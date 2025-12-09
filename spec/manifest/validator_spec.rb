# spec/manifest/validator_spec.rb
require "time"
require_relative "../../lib/goico/manifest/validator"

RSpec.describe Goico::Manifest::Validator do
  let(:good_manifest) do
    {
      "app_path" => "/opt/myapp",
      "generated_at" => Time.now.utc.iso8601,
      "capabilities" => {
        "ruby" => "3.2.0",
        "app_server" => "puma",
        "database" => "postgres",
        "jobs" => "sidekiq",
        "storage" => "local",
        "javascript" => "esbuild",
        "images" => "vips",
        "css" => "tailwind",
        "webserver" => "nginx",
        "ssl" => false
      }
    }
  end

  it "validates a correct manifest" do
    expect(Goico::Manifest::Validator.validate!(good_manifest)).to be true
  end

  it "rejects missing top-level keys" do
    bad = good_manifest.dup
    bad.delete("app_path")
    expect { Goico::Manifest::Validator.validate!(bad) }.to raise_error(Goico::Manifest::ValidationError)
  end

  it "rejects invalid generated_at" do
    bad = good_manifest.dup
    bad["generated_at"] = "not-a-date"
    expect { Goico::Manifest::Validator.validate!(bad) }.to raise_error(Goico::Manifest::ValidationError)
  end

  it "rejects missing capability keys" do
    bad = good_manifest.dup
    bad["capabilities"].delete("jobs")
    expect { Goico::Manifest::Validator.validate!(bad) }.to raise_error(Goico::Manifest::ValidationError)
  end

  it "rejects non-boolean ssl key" do
    bad = good_manifest.dup
    bad["capabilities"]["ssl"] = "true"
    expect { Goico::Manifest::Validator.validate!(bad) }.to raise_error(Goico::Manifest::ValidationError)
  end
end
