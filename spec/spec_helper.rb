# encoding: utf-8
require "spec_helper"
require "open4"
require "fileutils"

SPEC_DIR = File.dirname(__FILE__)
SPEC_TMP = File.join(SPEC_DIR, "tmp")
SPEC_LOG = File.join(SPEC_TMP, "logger")
ENV_LOG  = File.join(SPEC_TMP, "env")
