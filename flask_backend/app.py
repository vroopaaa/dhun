from flask import Flask, request, jsonify, send_from_directory
import yt_dlp
import os
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

DOWNLOAD_DIRECTORY = 'downloads'

def download_youtube_video(url, output_dir = DOWNLOAD_DIRECTORY):
    ydl_opts = {
        'format': 'bestaudio/best',
        'postprocessors': [{
            'key': 'FFmpegExtractAudio',
            'preferredcodec': 'mp3',
            'preferredquality': '192',
        }],
        'outtmpl': os.path.join(output_dir, '%(title)s.%(ext)s'),
    }

    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        info_dict = ydl.extract_info(url, download=True)
        return ydl.prepare_filename(info_dict).replace('.webm', '.mp3')

@app.route('/download', methods=['POST'])
def download():
    data = request.get_json()
    url = data.get('url')
    if not url:
        return jsonify({'error': 'URL is required'}), 400

    try:
        file_path = download_youtube_video(url)
        filename = os.path.basename(file_path)
        return jsonify({'file_path': filename}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/downloads/<filename>', methods=['GET'])
def serve_file(filename):
    return send_from_directory(DOWNLOAD_DIRECTORY, filename)

if __name__ == '__main__':
    os.makedirs(DOWNLOAD_DIRECTORY, exist_ok=True)
    app.run(host='0.0.0.0', port=5000)
