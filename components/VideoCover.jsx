export default function VideoCover({ videoUrl, coverImage, alt = "课程封面" }) {
  return (
    <a
      href={videoUrl}
      target="_blank"
      rel="noopener noreferrer"
      className="video-cover-wrapper"
    >
      <img
        src={coverImage}
        alt={alt}
        className="video-cover-img"
      />
      <div className="video-cover-overlay">
        <div className="video-cover-play-btn">
          <svg
            width="32"
            height="32"
            viewBox="0 0 24 24"
            fill="none"
            className="video-cover-play-icon"
          >
            <path d="M8 5v14l11-7L8 5z" fill="#1a1a1a" />
          </svg>
        </div>
      </div>
    </a>
  )
}
