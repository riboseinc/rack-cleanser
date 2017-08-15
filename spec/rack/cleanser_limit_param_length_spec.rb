require 'spec_helper'

RSpec.describe 'Rack::Cleanser.limit_param_length' do

  shared_examples_for '413 responses' do
    it "returns 413" do
      expect(last_response.status).to eq 413
    end
  end

  shared_examples_for '200 responses' do
    it "returns 200" do
      expect(last_response.status).to eq 200
    end
  end

  shared_context 'input hash' do |threshold|
    context "if any input value is over #{threshold} chars" do
      let(:params) { { a: 'a' * threshold + 'b' } }

      it_behaves_like '413 responses'
    end

    context "if any input value is <= #{threshold} chars" do
      let(:params) { { a: 'a' * threshold } }

      it_behaves_like '200 responses'
    end

    context "if any deep input value is over #{threshold} chars" do
      let(:params) { { a: { b: { c: 'a' * threshold + 'b' } }, b: 'a' * threshold } }

      it_behaves_like '413 responses'
    end

    context "if any deep input value is <= #{threshold} chars" do
      let(:params) { { a: { b: { c: 'a' * threshold } }, b: 'a' * threshold } }

      it_behaves_like '200 responses'
    end
  end

  context 'with no user-default' do

    let(:path) { '/test' }

    context 'with block that always return 10' do
      before do
        Rack::Cleanser.limit_param_length('random name') do |_env|
          10
        end
      end

      before do
        post path, params
      end

      include_context 'input hash', 10
    end

    context 'with block differentiating between paths' do

      before do
        Rack::Cleanser.limit_param_length('random name') do |env|
          case env['PATH_INFO']
          when %r{\A/hello/?\z}
            5
          when %r{\A/hello.*\z}
            25
          end
        end
      end

      before do
        post path, params
      end

      %w[
        /hellw
        /hell/world
        /hellmat
      ].each do |path_info|
        context "if PATH_INFO is #{path_info}" do
          let(:path) { path_info }

          include_context 'input hash', 2048
        end
      end

      %w[
        /hellow
        /hello/world
        /hellomat
      ].each do |path_info|
        context "if PATH_INFO is #{path_info}" do
          let(:path) { path_info }

          include_context 'input hash', 25
        end
      end

      %w[
        /hello
        /hello/
      ].each do |path_info|
        context "if PATH_INFO is #{path_info}" do
          let(:path) { path_info }

          include_context 'input hash', 5
        end
      end
    end
  end

  context 'with user-default' do

    context 'with block that always return 10' do
      before do
        Rack::Cleanser.limit_param_length('random name', default: 20) do |_env|
          10
        end
      end

      %w[
        /hellow
        /hello/world
        /hellomat
        /hello
        /hello/
      ].each do |path_info|
        context "if PATH_INFO is #{path_info}" do
          let(:path) { path_info }

          before do
            post path, params
          end

          include_context 'input hash', 10
        end
      end
    end

    context 'with block differentiating between paths' do

      before do
        Rack::Cleanser.limit_param_length('random name', default: 20) do |env|
          case env['PATH_INFO']
          when %r{\A/hello/?\z}
            5
          when %r{\A/hello.*\z}
            25
          end
        end
      end

      %w[
        /hellow
        /hello/world
        /hellomat
      ].each do |path_info|
        context "if PATH_INFO is #{path_info}" do
          let(:path) { path_info }

          before do
            post path, params
          end

          include_context 'input hash', 25
        end
      end

      %w[
        /hello
        /hello/
      ].each do |path_info|
        context "if PATH_INFO is #{path_info}" do
          let(:path) { path_info }

          before do
            post path, params
          end

          include_context 'input hash', 5
        end
      end
    end

  end

end
