# encoding: utf-8
require "spec_helper"

describe LTSPSession do

  before :all do
    @session = LTSPSession.new
    @socket = SPEC_TMP+"/var/run/ldm_socket_0_server"
    ENV["LTSP_FATCLIENT"] = "False"
  end

  after :all do
    FileUtils.rmtree SPEC_TMP
  end

  before :each do
    ENV["PAM_TYPE"]    = ""
    ENV["PAM_USER"]    = ""
    ENV["PAM_SERVICE"] = ""
    ENV["PAM_TTY"]     = ""
  end


  describe "auth" do
    it "should exit 1 without PAM_USER" do
      ENV["PAM_TYPE"]    = "auth"
      ENV["PAM_SERVICE"] = "lightdm"
      @session.exec
      @session.stderr.read.should == ""
      @session.exitcode.should == 1
    end

    it "should exit 0 with PAM_USER lightdm" do
      ENV["PAM_TYPE"]    = "auth"
      ENV["PAM_USER"]    = "lightdm"
      ENV["PAM_SERVICE"] = "lightdm"
      @session.exec
      @session.stderr.read.should == ""
      @session.exitcode.should == 0
    end

    it "should exit 1 with unsupported PAM_SERVICE" do
      ENV["PAM_TYPE"]    = "auth"
      ENV["PAM_USER"]    = "nobody"
      ENV["PAM_SERVICE"] = "ssh"
      @session.exec
      @session.stderr.read.should == ""
      @session.exitcode.should == 1
    end

    it "should set XAUTHORITY with lightdm" do
      ENV["PAM_TYPE"]    = "auth"
      ENV["PAM_USER"]    = "nobody"
      ENV["PAM_SERVICE"] = "lightdm"
      ENV["PAM_TTY"]     = ":0"
      @session.exec
      @session.stderr.read.should == ""
      @session.exitcode.should == 0
      @session.exports["XAUTHORITY"].should == SPEC_TMP+"/var/run/lightdm/root/:0"
    end

    it "should set XAUTHORITY with gdm" do
      ENV["PAM_TYPE"]    = "auth"
      ENV["PAM_USER"]    = "nobody"
      ENV["PAM_SERVICE"] = "gdm"
      ENV["PAM_TTY"]     = ":0"
      @session.exec
      @session.stderr.read.should == ""
      @session.exitcode.should == 0
      @session.exports["XAUTHORITY"].should == SPEC_TMP+"/var/run/gdm/auth-for-gdm-XXXXXX/database"
    end

    it "should create ssh control socket" do
      ENV["PAM_TYPE"]    = "auth"
      ENV["PAM_USER"]    = "usr1"
      ENV["PAM_SERVICE"] = "lightdm"
      ENV["PAM_TTY"]     = ":0"
      @session.exec
      @session.stderr.read.should == ""
      @session.exitcode.should == 0

      log = @session.log
      log[/^shm_askpass --write/].should_not be_nil
      ssh_cmd = log[/^daemon -i -- (ssh .*)/,1]
      ssh_cmd.should_not be_nil
      # assert socket
      ssh_cmd[/-S (\S+)/,1].should == @socket
      # assert user
      ssh_cmd[/-l (\S+)/,1].should == "usr1"
      # assert server
      ssh_cmd[/(\S+)$/].should == "server"

      # assert socket is created
      File.exist?(@socket).should be_true
    end

    it "should mount user home directory" do
      ENV["PAM_TYPE"]    = "auth"
      ENV["PAM_USER"]    = "usr1"
      ENV["PAM_SERVICE"] = "lightdm"
      ENV["PAM_TTY"]     = ":0"
      @session.exec
      @session.stderr.read.should == ""
      @session.exitcode.should == 0

      log = @session.log
      exports = @session.exports
      exports["LDM_SERVER"].should == "server"
      exports["LDM_SOCKET"].should == @socket
      exports["PAM_USER"].should == "usr1"
      # UID and GID are mocked in spec/mock/bin/getent
      exports["PAM_USER_UID"].should == "1001"
      exports["PAM_USER_GID"].should == "1001"
      exports["SSHFS_HOME"].should == "true"
      ldm_home = exports["LDM_HOME"]
      ldm_home.should == SPEC_TMP+"/home/usr1"
      File.exist?(ldm_home).should be_true
      log[/^chown \S+ (.*)/,1].should == ldm_home

      sshfs_cmd = log[/^sshfs .*/]
      sshfs_cmd.should_not be_nil

      # assert socket
      sshfs_cmd[/ControlPath=(\S+)/,1].should == @socket

      match = /-o \S+ (.*):(.*) (.*)/.match(sshfs_cmd)
      server = match[1]
      remote_home = match[2]
      local_home = match[3]

      server.should == "server"
      remote_home.should == ldm_home
      local_home.should == ldm_home
    end
  end


  describe "open_session" do
    it "should call scripts and set variables" do
      ENV["PAM_TYPE"]    = "open_session"
      ENV["PAM_USER"]    = "usr1"
      ENV["PAM_SERVICE"] = "lightdm"
      ENV["PAM_TTY"]     = ":0"
      @session.exec
      @session.stderr.read.should == ""
      @session.exitcode.should == 0

      log = @session.log
      log[/^xinitrc/].should_not be_nil
      log[/^ldm-script pressh/].should_not be_nil
      log[/^ldm-script start/].should_not be_nil
      log[/^daemon .*/][/ldm-script xsession/].should_not be_nil

      exports = @session.exports
      exports["LDM_SERVER"].should == "server"
      exports["LDM_SOCKET"].should == @socket
      exports["LDM_USERNAME"].should == "usr1"
      exports["LDM_XSESSION"].should == SPEC_TMP+"/etc/X11/Xsession"
      exports["XAUTHORITY"].should_not be_nil

      # socket should be created in auth phase
      File.exist?(@socket).should_not be_true
    end
  end


  describe "close_session" do
    it "should close socket" do
      ENV["PAM_TYPE"]    = "close_session"
      ENV["PAM_USER"]    = "usr1"
      ENV["PAM_SERVICE"] = "lightdm"
      ENV["PAM_TTY"]     = ":0"
      @session.exec
      @session.stderr.read.should == ""
      @session.exitcode.should == 0

      ssh_cmd = @session.log[/^ssh .*/]
      ssh_cmd.should_not be_nil
      # assert socket
      ssh_cmd[/-S (\S+)/,1].should == @socket
      # assert exit
      ssh_cmd[/-O exit/].should_not be_nil
      # assert server
      ssh_cmd[/(\S+)$/].should == "server"
    end
  end

end
