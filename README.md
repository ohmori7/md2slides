# md2slides
*md2slides* generates a Google presentation from a markdown file.
A video file of a presentation will be also generated, and it may contains narration if supplied.
Narration can be given as notes in slides, and the audio will be generated using Google text-to-speech API.

# Quick start
1. copy Google API credentails.json if necessary:
```
% cat >> config/credentials.json
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
2. install ffmpeg if necessary (if producing video file automatically).

3. install necessary gems.
```
% bundle install --path vendor/bundle
```

4. create an empty Google slide.

5. write a markdown file.
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

6. execute.
```
bundle exec bin/md2slides doc/sample.md
```

7. the Google presentation is updated, and the video is stored in `data/.`
