import React from "react";
import PropTypes from "prop-types";

/**
 * Source: https://dev.to/bravemaster619/simplest-way-to-embed-a-youtube-video-in-your-react-app-3bk2
 * Author: bravemaster619
 * Site: http://dev.to
 */

const YouTubeEmbed = ({ embedId }) => (
  <div class="mx-3 place-content-end">
    <iframe
      width={window.innerWidth / 3.3}
      height={window.innerHeight / 3.3}
      src={`https://www.youtube.com/embed/${embedId}`}
      frameBorder="0"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
      allowFullScreen
      color="white"
      modestbranding="1"
      fs="0"
      title="Embedded YouTube player"
    />
    <p></p>
  </div>
);

YouTubeEmbed.propTypes = {
  embedId: PropTypes.string.isRequired
};

export default YouTubeEmbed;
