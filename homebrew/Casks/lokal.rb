# Source of truth for the Lokal cask. The release workflow updates version and sha256 and
# mirrors this file verbatim to https://github.com/sigurdarson/homebrew-tap/blob/main/Casks/lokal.rb.
# Do not edit the copy in the tap.
cask "lokal" do
  version "0.1.0"
  sha256 "bdc9c7a3e8226629a678bcbbbf3f3b5d139e5b21b1cfe33233255d67260b5ac1"

  url "https://github.com/sigurdarson/lokal/releases/download/v#{version}/Lokal-#{version}.dmg"
  name "Lokal"
  desc "Menu bar app that shows what is running on localhost"
  homepage "https://lokal.sigurdarson.is/"

  livecheck do
    url "https://lokal.sigurdarson.is/appcast.xml"
    strategy :sparkle, &:short_version
  end

  auto_updates true
  depends_on arch: :arm64
  depends_on macos: :sequoia

  app "Lokal.app"

  zap trash: [
    "~/Library/Application Support/Lokal",
    "~/Library/Caches/is.sigurdarson.lokal",
    "~/Library/HTTPStorages/is.sigurdarson.lokal",
    "~/Library/Preferences/is.sigurdarson.lokal.plist",
  ]
end
