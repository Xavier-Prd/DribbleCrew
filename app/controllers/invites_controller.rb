class InvitesController < ApplicationController
  def qrcode
    url = "https://www.dribblecrew.site"
    qr  = RQRCode::QRCode.new(url)
    svg = qr.as_svg(module_size: 6, standalone: true, use_path: true, color: "000", background_color: "fff")
    w   = svg.match(/width="(\d+)"/)[1]
    h   = svg.match(/height="(\d+)"/)[1]
    @qr_svg = svg
      .gsub(/width="\d+"/, 'width="280"')
      .gsub(/height="\d+"/, 'height="280"')
      .gsub(/<svg /, %(<svg viewBox="0 0 #{w} #{h}" ))
  end
end
