# frozen_string_literal: true

require_relative "goico/version"

# Core autoloads (lazy-loading subsystems)
module Goico
  autoload :CLI,           "goico/cli/root"

  module Core
    autoload :Config,      "goico/core/config"
    autoload :Errors,      "goico/core/errors"
    autoload :I18nHelper,   "goico/core/i18n"
  end

  module Analyzer
    autoload :Base,        "goico/analyzer/base"
    autoload :AppServer,   "goico/analyzer/app_server"
    autoload :Gems,        "goico/analyzer/gems"
    autoload :Database,    "goico/analyzer/database"
  end

  module Packager
    autoload :Base,        "goico/packager/base"
    autoload :Deb,         "goico/packager/deb"
    autoload :Tar,         "goico/packager/tar"
    autoload :Rpm,         "goico/packager/rpm"
    autoload :Homebrew,    "goico/packager/homebrew"
  end

  module Installer
    autoload :ServiceGenerator, "goico/installer/service_generator"
    autoload :Postinstall,      "goico/installer/postinstall"
  end

  module Manifest
    autoload :Model,       "goico/manifest/model"
    autoload :Serializer,  "goico/manifest/serializer"
  end
end

# initialize localization (loads locales)
require_relative "goico/core/i18n"
