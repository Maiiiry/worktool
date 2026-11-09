# 0014 本機只測改到的 spec，全部 tier 交由 CI

- 狀態：已採納（2026-10-01）
- 討論：#300（決策與驗收）；取代 #274 的「本機 lint + unit 整層 + 改動觸及的層」決議
- 修訂：2026-10-02，依 #376 的範圍與驗收修訂決策 6，取消未知影響時的本機完整 unit fallback。
- 修訂：2026-10-02，依 #378 加入共用守門清單與 `just test guards`。
- 修訂：2026-11-09，依 #756 修訂決策 2：推送前的本機 gate 改為 `just test lint` 加改到的 spec，`just test changed` 改為選用。原本否決的「本機只跑當下 spec，不跑 changed」改為採用，理由見「決策 2 的修訂理由」。

## 背景

#274 決定 agent 在本機執行 lint、完整 unit tier，以及改動觸及的其他 tier。隨著測試層與實機案例增加，完整 tier 會重複 CI 已負責的工作，也讓每個 TDD 切片等待與該切片無關的案例。

#298 提供 `just test <tier> <spec...> [--filter REGEX]`，本機因此能精準執行當下 spec。#299 提供 `just test changed`，可依 diff 補跑受影響的 spec。原決策把它列為推送前必跑的 gate；#756 依實際成本把它改為選用，推送前只跑 lint 與改到的 spec，其餘交給 CI。

## 決策

1. TDD 的 RED/GREEN 迴圈只執行當下切片的 spec：`just test <tier> <spec...> [--filter REGEX]`。本機不得執行完整 tier。
2. 每次推送前，本機執行 `just test lint`，加上這次改到的 spec（`just test <tier> <spec...> [--filter REGEX]`）。`test/system-real/` 與 `test/system/real_engine_spec.bats` 交由 CI。`just test changed` 不是推送前的必跑步驟；它仍是可選指令，開發者或呼叫端（pr-loop 的 `gates`）可以明確要求執行。本條是推送前本機 gate 的唯一定義，`AGENTS.md` 與 `doc/workflow.md` 引用此處。
3. GitHub CI 執行全部 tier，作為 branch protection 所需 `ci-passed` 的完整驗證。
4. 所有測試仍只經 `just test ...` 在 Docker 內執行；本決策只改變本機選取範圍，不建立另一套測試入口。
5. 本決策取代 #274 要求本機執行完整 unit tier 的部分。
6. `just test changed` 的自動選取執行 lint、改到或映射到的 unit spec 與 matrix spec；依 #378，改到 `script/`、`lib/`、`box/`、`justfile*`、`doc/adr/` 時加跑 `script/test/test.sh` 的整份共用守門清單，其中 config mutation 僅保留便宜的 drift guards，亦可透過 `just test guards` 明確執行；config mutation 案例則在其輸入變更時執行：由共用表格推導的 `lib/config.sh`、owner 模組與 case spec，以及 mutation spec 本身與共用 helper；CI 仍執行全部案例。依 #376，無法判定影響、缺少映射 spec、測試基礎設施變更或無法讀取 diff 時，列出檔名（若可取得）與原因，提示交由 CI 驗證，不在本機跑整層；同次改動已選出的 spec 仍執行。integration、system、system-real、acceptance 與 Ghostty／system-real runner 映像一律提示並交由 CI 驗證，開發者仍可明確執行個別重 tier 指令。

### 決策 2 的修訂理由（#756）

維護者 2026-11-09 決定：

> 電腦效能有限的情況下 ci runner 比較適合處理這個問題, 後續我會在新增 host 的 runner

依據是 M3 總掃期間的觀察：

- 沒有任何一個 commit 出現「本機 changed 紅、CI 卻綠」。
- 本機 changed 每次失敗（#713），失敗的都是 CI 也會跑的 spec，CI 一樣抓得到。
- 本機跑一次 changed 要 15 到 25 分鐘，並造成 pr-loop 逾時；#755 (b) 記錄了 #714 的 resume 發布兩次都在 590 秒時被終止，結果沒有推送，也沒有開 PR。

原本否決「只跑當下 spec」的理由是「可能漏掉相鄰回歸」。這類回歸改由 CI 的全部 tier 擋下，`ci-passed` 是合併的必要條件；代價是要等到 CI 才看到，而不是推送前。

## 影響

- `.claude/workflows/pr-loop.js` 的預設 gate 在 full 與 light 都是 `just test lint` 加改到的 spec（排除 system-real），不再預設跑 `just test changed`；Implement、Fix 與 CI 修復在 codex、Claude 兩種路徑共用同一組本機測試規則。
- `.claude/workflows/milestone-fanout.js` 將每個 item 的 `gates` 原樣轉傳；未指定時由 `pr-loop` 使用上述預設。
- `test/unit/workflow_spec.bats` 從 workflow 公開輸出驗證：兩種 implementer 的 Implement 與 Fix 提示、預設 gate 實際執行的指令，以及不再要求本機跑完整 tier 或 `just test changed`。
- 完整測試覆蓋的證據由 GitHub CI 留存；本機證據包含切片 spec 的 RED/GREEN，以及推送前 lint 與改到的 spec 的結果。

## 被取代的方案

- **本機固定跑完整 unit tier。** 這是 #274 的決議；完整驗證已由 CI 負責，本機重跑會拉長每個切片的回饋時間。
- **本機跑全部 tier。** 與 CI 重複，且 system-real 等 tier 成本高，不適合作為每個切片或每次推送的本機 gate。
- **推送前必跑 `just test changed`。** 這是本 ADR 原本的決策 2，依 #756 推翻。它在本機的耗時讓 pr-loop 逾時，而它抓到的失敗 CI 也都抓得到，理由見「決策 2 的修訂理由」。原本列在此處的「本機只跑當下 spec，不跑 changed」已改為採用（決策 2）。
