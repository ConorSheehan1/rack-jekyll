# encoding: UTF-8

require_relative "helper"


describe "when handling requests" do

  before do
    @tempdir = File.join(TEST_DIR, "tmp")
    FileUtils.mkdir_p(@tempdir)  unless File.exist?(@tempdir)
    Dir.chdir(@tempdir)

    @sourcedir = File.join(TEST_DIR, "source")
    @destdir   = File.join(@tempdir, "_site")
    FileUtils.mkdir_p(@sourcedir)  unless File.exist?(@sourcedir)
    FileUtils.mkdir_p(@destdir)    unless File.exist?(@destdir)

    @jekyll = rack_jekyll(:force_build => true,
                          :source      => @sourcedir,
                          :destination => @destdir)
    @request = Rack::MockRequest.new(@jekyll)
  end

  after do
    FileUtils.rm_rf(@tempdir)  if File.exist?(@tempdir)
  end

  it "can be created" do
    @jekyll.wont_be_nil
    @request.wont_be_nil
  end

  it "should return correct http status code" do
    @request.get("/").status.must_equal 200
    @request.get("/show/me/404").status.must_equal 404
  end

  it "should return correct http status code for If-Modified-Since" do
    modify_time = @request.get("/").headers["Last-Modified"]
    earlier_time = (Time.parse(modify_time) - 3600).httpdate

    @request.get("/", {"HTTP_IF_MODIFIED_SINCE" => modify_time}).status.must_equal 304
    @request.get("/", {"HTTP_IF_MODIFIED_SINCE" => earlier_time}).status.must_equal 200
  end

  it "should return correct http status code for If-Modified-Since with 404s" do
    modify_time = @request.get("/").headers["Last-Modified"]
    earlier_time = (Time.parse(modify_time) - 3600).httpdate

    @request.get("/show/me/404", {"HTTP_IF_MODIFIED_SINCE" => earlier_time}).status.must_equal 404
  end

  it "should return correct Content-Type header" do
    @request.get("/").headers["Content-Type"].must_equal "text/html"
    @request.get("/css/test.css").headers["Content-Type"].must_equal "text/css"
    @request.get("/js/test.js").headers["Content-Type"].must_equal "application/javascript"
    @request.get("/js/test.min.js").headers["Content-Type"].must_equal "application/javascript"
    @request.get("/show/me/404").headers["Content-Type"].must_equal "text/html"
  end

  it "should return correct Content-Length header" do
    @request.get("/").original_headers["Content-Length"].to_i.must_equal 24
    @request.get("/show/me/404").original_headers["Content-Length"].to_i.must_equal 9
  end

  it "should return correct Content-Length header for If-Modified-Since" do
    modify_time = @request.get("/").headers["Last-Modified"]
    @request.get("/", {"HTTP_IF_MODIFIED_SINCE" => modify_time}).original_headers["Content-Length"].must_be_nil
  end

  it "should return correct body" do
    @request.get("/").body.must_equal "<p>Rack-Jekyll Test</p>\n"
    @request.get("/show/me/404").body.must_equal "Not found"
  end


  describe "when page contains multibyte characters" do

    before do
      @response = @request.get("/buenos_dias.html")
    end

    it "should return correct body" do
      @response.body.must_equal "<p>¡Buenos días!</p>\n"
    end

    it "should return the bytesize as Content-Length header" do
      @response.original_headers["Content-Length"].to_i.must_equal 23
    end
  end
end
