require 'spec_helper'

describe 'Website assets', :js, type: :feature do
  it 'loads content-versioned images, styles and scripts on visit and reload' do
    visit '/'

    2.times do
      icon = "/img/icon.png?v=#{Digest::SHA256.file('public/img/icon.png').hexdigest}"
      expect(page).to have_css("img[src='#{icon}']")
      expect(page.evaluate_script('typeof jQuery')).to eq 'function'
      expect(page.evaluate_script('Array.from(document.images).filter(img => img.origin === location.origin || img.getAttribute("src").startsWith("/")).every(img => img.complete && img.naturalWidth > 0)')).to be true
      expect(page.evaluate_script('Array.from(document.styleSheets).some(sheet => sheet.href && /\\/styles\\.css\\?v=[a-f0-9]{64}$/.test(sheet.href) && sheet.cssRules.length > 0)')).to be true
      page.refresh
    end
  end
end
