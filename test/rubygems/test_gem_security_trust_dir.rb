require 'rubygems/test_case'

class TestGemSecurityTrustDir < Gem::TestCase

  def setup
    super

    @dest_dir = File.join @tempdir, 'trust'

    @trust_dir = Gem::Security::TrustDir.new @dest_dir
  end

  def test_cert_path
    digest = OpenSSL::Digest::SHA1.hexdigest PUBLIC_CERT.subject.to_s

    expected = File.join @dest_dir, "cert-#{digest}.pem"

    assert_equal expected, @trust_dir.cert_path(PUBLIC_CERT)
  end

  def test_trust_cert
    @trust_dir.trust_cert PUBLIC_CERT

    trusted = @trust_dir.cert_path PUBLIC_CERT

    assert_path_exists trusted

    mask = 0100600 & (~File.umask)

    assert_equal mask, File.stat(trusted).mode unless win_platform?

    assert_equal PUBLIC_CERT.to_pem, File.read(trusted)
  end

  def test_verify
    refute_path_exists @dest_dir

    @trust_dir.verify

    assert_path_exists @dest_dir

    mask = 040700 & (~File.umask)

    assert_equal mask, File.stat(@dest_dir).mode unless win_platform?
  end

  def test_verify_file
    FileUtils.touch @dest_dir

    e = assert_raises Gem::Security::Exception do
      @trust_dir.verify
    end

    assert_equal "trust directory #{@dest_dir} is not a directory", e.message
  end

  def test_verify_wrong_permissions
    FileUtils.mkdir_p @dest_dir, :mode => 0777

    @trust_dir.verify

    mask = 040700 & (~File.umask)

    assert_equal mask, File.stat(@dest_dir).mode unless win_platform?
  end

end
