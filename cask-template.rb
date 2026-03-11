cask "gather-windows" do
  version "VERSION_PH"
  sha256 "SHA256_PH"

  url "URL_PH"
  name "Gather Windows"
  desc "Move windows from external displays to a target display"
  homepage "HOMEPAGE_PH"

  depends_on macos: ">= :sonoma"

  app "Gather Windows.app"

  binary "#{appdir}/Gather Windows.app/Contents/MacOS/Gather Windows", target: "gather-windows"

  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-cr", "#{appdir}/Gather Windows.app"]
  end

  zap trash: [
    "~/Library/Preferences/com.vibed.gather-windows.plist",
  ]
end
