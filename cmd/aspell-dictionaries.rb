# typed: strict
# frozen_string_literal: true

require "abstract_command"
require "resource"
require "formula"

module Homebrew
  module Cmd
    class AspellDictionariesCmd < AbstractCommand
      cmd_args do
        usage_banner <<~EOS
          `aspell-dictionaries`

          Generates the new dictionaries for the `aspell` formula.
        EOS
      end

      FILE_PATH_REGEX = T.let(%r{
        <td[^>]*?>.*?href=["']?
        (?<path>[^"' >]*?(?<language>[^/]+)/aspell[^"' >]+\.t[^/"' >]+)
      }ix, Regexp)

      sig { override.void }
      def run
        dictionary_url = "https://ftp.gnu.org/gnu/aspell/dict"
        dictionary_mirror = "https://ftpmirror.gnu.org/aspell/dict"
        index_url = "#{dictionary_url}/0index.html"
        languages = {}

        result = Utils::Curl.curl_output("--fail", index_url)
        raise "Unable to fetch language index page: #{index_url}" unless result.success?

        result.stdout.scan(FILE_PATH_REGEX).each do |match|
          # The first capture group is the file path (e.g. `en/aspell6-en-2020.12.07-0.tar.bz2`)
          # The second capture group is the language (e.g. `en`)
          languages[T.must(match[1]).tr("-", "_")] = match[0]
        end
        raise "Unable to identify languages at #{index_url}" if languages.blank?

        resources = languages.map do |language, path|
          r = Resource.new(language)
          r.owner = Formula["aspell"]
          r.url "#{dictionary_url}/#{path}"
          r.mirror "#{dictionary_mirror}/#{path}"
          r
        end

        output = resources.map do |resource|
          resource.fetch(verify_download_integrity: false)

          <<-EOS
            resource "#{resource.name}" do
              url "#{resource.url}"
              mirror "#{resource.mirrors.first}"
              sha256 "#{resource.cached_download.sha256}"
            end

          EOS
        end

        puts output
      end
    end
  end
end
