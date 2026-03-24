#!/usr/bin/env bash
# Command: templates

cmd_templates() {
  api_get "$API_BASE/brand-templates?q=mine" | output
}
