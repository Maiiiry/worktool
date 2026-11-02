# justfile - worktool user interface entry (auto-discovered by `just`).
#
# `just` IS the interface, modelled on ycpss91255-docker/base
# (ADR-00000005/10/11): zero special cases - every action is a namespace
# declared with `mod?` below and nothing else lives at this level; the
# namespaces are action-named (test, box; never ci/cd); bare `just <ns>`
# runs the most (`just test` = everything CI runs) and sub-recipes only
# narrow; every recipe is a thin forwarder that hands its arguments to the
# script under script/<ns>/ verbatim - ALL validation, usage text and
# --help live in those scripts. Bare `just` lists the namespaces.
#
# The doc comment above each `mod?` is what `just --list` shows for it.

# Self-tests in Docker; just --list test lists all recipes.
mod? test 'script/test/justfile.test'
# Dev box lifecycle; see just box help for actions and options.
mod? box 'script/box/justfile.box'
# Acceptance checks of doc/acceptance.md; see just verify help for actions and options.
mod? verify 'script/verify/justfile.verify'
# Agent launch without GitHub authentication; just agent lists actions.
mod? agent 'script/agent/justfile.agent'

# Cleanup merged linked worktrees (dry-run by default); just worktree lists actions.
mod? worktree '.agents/script/worktree/justfile.worktree'


# Detached agent jobs and compact results; see just job help for actions and options.
mod? job '.agents/script/justfile.job'

# Default: list the namespaces.
default:
    @just --list
