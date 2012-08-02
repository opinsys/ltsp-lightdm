# encoding: utf-8
require "spec_helper"

class LTSPSession

  SCRIPT = "#{SPEC_DIR}/../hack/usr/share/ltsp/ltsp-session"

  attr_reader :stdin, :stdout, :stderr, :exitcode

  def initialize
    # add spec/bin to PATH
    spec_bin = File.join(SPEC_DIR, 'bin')
    ruby_bin = RbConfig::CONFIG["bindir"]
    ENV["PATH"] = "#{spec_bin}:#{ruby_bin}:/bin"
    ENV["SOCKETDIR"] = SPEC_TMP
    ENV["ENV_DEBUG"] = ENV_LOG
    ENV["SPEC_LOG"] = SPEC_LOG
  end

  def exec *params
    @pid, @stdin, @stdout, @stderr = Open4::popen4 "bash #{SCRIPT} #{params}"
    ignored, status = Process::waitpid2 @pid
    @exitcode = status.exitstatus
  end

  # read the exported env variables
  def exports
    File.exist?(ENV_LOG) or return {}
    env = {}
    File.read(ENV_LOG).each_line do |row|
      (var, val) = row.strip.split("=")
      env[var] = val
    end
    env
  end

end


describe LTSPSession do

  before :each do
    FileUtils.rmtree SPEC_TMP
    FileUtils.mkdir SPEC_TMP
  end

  after :all do
    FileUtils.rmtree SPEC_TMP
  end


  it "should exist" do
    File.exist?(LTSPSession::SCRIPT).should be_true
  end

  it "should exit 1 without PAM_USER" do
    session = LTSPSession.new
    session.exec
    session.stderr.read.should == ""
    session.exitcode.should == 1
  end

  it "should exit 0 with any PAM_USER other than lightdm" do
    ENV["PAM_USER"] = "nobody"
    session = LTSPSession.new
    session.exec
    session.stderr.read.should == ""
    session.exitcode.should == 0
    # no log, nothing happened
    File.exist?(SPEC_LOG).should_not be_true
  end

  it "should set XAUTHORITY with lightdm" do
    ENV["PAM_USER"] = "nobody"
    ENV["PAM_TYPE"] = "auth"
    ENV["PAM_SERVICE"] = "lightdm"
    ENV["PAM_TTY"] = ":0"
    session = LTSPSession.new
    session.exec
    session.stderr.read.should == ""
    session.exitcode.should == 0
    session.exports["XAUTHORITY"].should == "/var/run/lightdm/root/:0"
  end

  it "should create ssh control socket" do
    ENV["PAM_USER"] = "nobody"
    ENV["PAM_TYPE"] = "auth"
    ENV["PAM_SERVICE"] = "lightdm"
    ENV["PAM_TTY"] = ":0"
    session = LTSPSession.new
    session.exec
    session.stderr.read.should == ""
    session.exitcode.should == 0
    File.exist?(SPEC_TMP+"/ldm_socket_0_server").should be_true
  end


end
