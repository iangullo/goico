# spec/integration/system_packages_spec.rb
RSpec.describe Goico::Installer::SystemPackages do
  it "resolves full stack packages correctly" do
    caps = {
      database: :postgres,
      jobs: :sidekiq,
      javascript: :esbuild,
      images: :vips,
      webserver: :nginx,
      ssl: true
    }

    pkgs = described_class.resolve(caps)

    expect(pkgs).to include(
      "postgresql-client",
      "redis-server",
      "nodejs",
      "libvips",
      "nginx",
      "openssl"
    )
  end
end
