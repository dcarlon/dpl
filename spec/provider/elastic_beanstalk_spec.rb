require 'spec_helper'
require 'aws-sdk-v1'
require 'dpl/provider'
require 'dpl/provider/elastic_beanstalk'

describe DPL::Provider::ElasticBeanstalk do

  before (:each) do
    AWS.stub!
  end

  let(:access_key_id) { 'qwertyuiopasdfghjklz' }
  let(:secret_access_key) { 'qwertyuiopasdfghjklzqwertyuiopasdfghjklz' }
  let(:region) { 'us-west-2' }
  let(:app) { 'example-app' }
  let(:env) { 'live' }
  let(:bucket_name) { "travis-elasticbeanstalk-test-builds-#{region}" }
  let(:bucket_path) { "some/app"}

  let(:bucket_mock) do
    dbl = double("bucket mock", write: nil)
    allow(dbl).to receive(:objects).and_return(double("Hash", :[] => dbl))
    dbl
  end
  let(:s3_mock) do
    hash_dbl = double("Hash", :[] => bucket_mock, :map => [])
    double("AWS::S3", buckets: hash_dbl)
  end

  subject :provider do
    described_class.new(
      DummyContext.new, :access_key_id => access_key_id, :secret_access_key => secret_access_key,
      :region => region, :app => app, :env => env, :bucket_name => bucket_name, :bucket_path => bucket_path
    )
  end

  describe "#check_auth" do
    example do
      expect(AWS).to receive(:config).with(access_key_id: access_key_id, secret_access_key: secret_access_key, region: region)
      provider.check_auth
    end
  end

  describe "#push_app" do

    let(:bucket_name) { "travis-elasticbeanstalk-test-builds-#{region}" }
    let(:app_version) { Object.new }

    example 'bucket exists already' do
      allow(s3_mock.buckets).to receive(:map).and_return([bucket_name])

      expect(provider).to receive(:s3).and_return(s3_mock).twice
      expect(provider).not_to receive(:create_bucket)
      expect(provider).to receive(:create_zip).and_return('/path/to/file.zip')
      expect(provider).to receive(:archive_name).and_return('file.zip')
      expect(bucket_mock.objects).to receive(:[]).with("#{bucket_path}/file.zip").and_return(bucket_mock)
      expect(provider).to receive(:upload).with('file.zip', '/path/to/file.zip').and_call_original
      expect(provider).to receive(:sleep).with(5)
      expect(provider).to receive(:create_app_version).with(bucket_mock).and_return(app_version)
      expect(provider).to receive(:update_app).with(app_version)

      provider.push_app
    end

    example 'bucket doesnt exist yet' do
      expect(provider).to receive(:s3).and_return(s3_mock).twice
      expect(provider).to receive(:create_bucket)
      expect(provider).to receive(:create_zip).and_return('/path/to/file.zip')
      expect(provider).to receive(:archive_name).and_return('file.zip')
      expect(provider).to receive(:upload).with('file.zip', '/path/to/file.zip').and_call_original
      expect(provider).to receive(:sleep).with(5)
      expect(provider).to receive(:create_app_version).with(bucket_mock).and_return(app_version)
      expect(provider).to receive(:update_app).with(app_version)

      provider.push_app
    end
  end
end
