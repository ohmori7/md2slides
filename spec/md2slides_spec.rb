RSpec.describe Md2slides do
  it "has a version number" do
    expect(Md2slides::VERSION).not_to be nil
  end

  it "filename sanitization" do
    expect(Presentation::filename_sanitize('abcdef/*?')).to eq('abcdef')
  end
end
