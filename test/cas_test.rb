require 'test_helper'
require 'casserver/cas'

# FIXME: This is not a real test suite, just patchy testing here and there.
class CasTest < Test::Unit::TestCase

  include CASServer::CAS

  def setup
  end

  def test_clean_service_url

    # these should be left unaltered
    dirty = "http://test.com/foo"
    assert_equal "http://test.com/foo", clean_service_url(dirty)
    dirty = "http://test.com/foo?goo=gaa"
    assert_equal "http://test.com/foo?goo=gaa", clean_service_url(dirty)

    # strip the trailing ?
    dirty = "http://test.com/foo?"
    assert_equal "http://test.com/foo", clean_service_url(dirty)

    # strip the trailing &
    dirty = "http://test.com/foo&"
    assert_equal "http://test.com/foo", clean_service_url(dirty)

    # url encoded service
    dirty = "http://test.com/foo?service=http%3A%2F%2Fexample.net%2Fhello%3Fservice%3D123%26ticket%3D586&something=else"
    assert_equal "http://test.com/foo?something=else", clean_service_url(dirty)

    # unencoded service url
    dirty = "http://test.com/foo?goo=gaa&service=http://moo.com/foo?blah=goo&wee=waa"
    assert_equal "http://test.com/foo?goo=gaa&wee=waa", clean_service_url(dirty)

    # a really nasty url
    dirty = "http://test.com/cq_update.php?id=1186&project_id=481&job_number=08506&project_name=Foo Bar&workflow_id=3425&ticket=12345&issue_id=589"
    assert_equal = "http://test.com/cq_update.php?id=1186&project_id=481&job_number=08506&project_name=Foo Bar&workflow_id=3425&issue_id=589", clean_service_url(dirty)

    # multiple ticket parameters (only the first one should be stripped)
    dirty = "http://test.com/foo?hello=goodbye&ticket=12345&ticket=ABCDEFG&what=that"
    assert_equal "http://test.com/foo?hello=goodbye&ticket=ABCDEFG&what=that", clean_service_url(dirty)
  end

end

