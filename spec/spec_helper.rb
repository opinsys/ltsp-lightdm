# encoding: utf-8
require "spec_helper"
require "open4"
require "fileutils"

SPEC_DIR = File.dirname(__FILE__)
SPEC_TMP = File.join(SPEC_DIR, "tmp")
SPEC_LOG = File.join(SPEC_TMP, "log")
ENV_LOG  = File.join(SPEC_TMP, "env")
SPEC_MOCKS = File.join(SPEC_DIR, "mock")


class LTSPSession

  SCRIPT = "#{SPEC_DIR}/../hack/usr/share/ltsp/ltsp-session"

  attr_reader :stdout, :stderr, :exitcode

  def initialize
    # add spec/tmp/bin and RVM ruby to PATH
    spec_bin = File.join(SPEC_TMP, 'bin')
    ruby_bin = RbConfig::CONFIG["bindir"]
    ENV["PATH"] = "#{spec_bin}:#{ruby_bin}"
    ENV["ENV_DEBUG"] = ENV_LOG
    ENV["SPEC_LOG"] = SPEC_LOG
    # change hardcoded file constants in the script
    # to point to tmp "chroot"
    @script = "#{SPEC_DIR}/src/ltsp-session"
    File.open @script, "w" do |file|
      file.write File.read(SCRIPT).
        gsub("/var", "#{SPEC_TMP}/var").
        gsub("/usr/share", "#{SPEC_TMP}/usr/share").
        gsub("/etc", "#{SPEC_TMP}/etc")
    end
    # delete the modified script upon exit
    ObjectSpace.define_finalizer(self, proc { File.delete(@script) })
  end

  # Copy mocks to tmp "chroot"
  def reset
    FileUtils.rmtree SPEC_TMP
    FileUtils.cp_r SPEC_MOCKS, SPEC_TMP, :preserve => true
  end

  # Run script
  def exec
    reset()
    @pid, stdin, @stdout, @stderr = Open4::popen4 "/bin/bash #{@script}"
    ignored, status = Process::waitpid2 @pid
    @exitcode = status.exitstatus
  end

  # Read the exported env variables
  def exports
    File.exist?(ENV_LOG) or return {}
    env = {}
    File.read(ENV_LOG).each_line do |row|
      (var, val) = row.strip.split("=")
      env[var] = val
    end
    env
  end

  # Read logger output and list of executed shell commands
  def log
    File.read(SPEC_LOG) rescue ""
  end

end
