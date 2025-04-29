# md2slides
*md2slides* generates a Google presentation from a markdown file.
A video file of a presentation will be also generated, and it may contains narration if supplied.
Narration can be given as notes in slides, and the audio will be generated using Google text-to-speech API and ffmpeg.

## Installation

install by gem:

    % gem install md2slides

Or add this line to your application's Gemfile:

```ruby
gem 'md2slides'
```

and then execute:

    $ bundle

## Quick start
1. Generate your Google API credentials and copy it to credentails.json:
```
% mkdir ~/.config/gcloud
% cat >> ~/.config/gcloud/credentials.json
{
  "type": "service_account",
  "project_id": "project-id",
  "private_key_id": "private-key-ID',
  "private_key": "-----BEGIN PRIVATE KEY-----\nhogehoge\n-----END PRIVATE KEY-----\n",
  "client_email": "hogehoge@hogehoge.iam.gserviceaccount.com",
  "client_id": "00000000000000000000",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/CLIENT.iam.gserviceaccount.com"
}
^D (this means CTRL + D)
```
2. install ffmpeg if necessary (if producing video file).

3. create an empty Google slide, share it with **client_email** user, and copy the URL.

4. write a markdown file.
```
cat >> doc/sample.md
---
title: hogehoge
url: <Google presentation URL>
---
# title of the first title page
## sub title or author's name(s)
<!--
narration text...
-->
---
# title of the page
- hogehoge
...
<!--
narration text...
-->
^D (this means CTRL + D)
```

5. run the script.
```
% md2slides sample.md
```

the Google presentation is updated, and the video is stored in the current directory.

## Usage

TODO: Write usage instructions here

## TODO

See [TODO.md](https://github.com/ohmori7/md2slides/blob/main/TODO.md "TODO.md")

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ohmori7/md2slides.
