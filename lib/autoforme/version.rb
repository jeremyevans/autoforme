# frozen-string-literal: true

module AutoForme
  # The major version of AutoForme, updated only for major changes that are
  # likely to require modification to apps using AutoForme.
  MAJOR = 1

  # The minor version of AutoForme, updated for new feature releases of AutoForme.
  MINOR = 7

  # The patch version of AutoForme, updated only for bug fixes from the last
  # feature release.
  TINY = 0

  # Version constant, use <tt>AutoForme.version</tt> instead.
  VERSION = "#{MAJOR}.#{MINOR}.#{TINY}".freeze

  # The full version of AutoForme as a number (1.8.0 => 10800)
  VERSION_NUMBER = MAJOR*10000 + MINOR*100 + TINY

  # Returns the version as a frozen string (e.g. '0.1.0')
  def self.version
    VERSION
  end
end
