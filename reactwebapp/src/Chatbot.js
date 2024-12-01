import React from "react";
import { Link } from "react-router-dom";
import "./Chatbot.css"; // Create this CSS file for styling if needed

function Chatbot() {
    return (
        <div className="chatbot-container">
            <h1>Hello</h1>
            <nav className="nav-bar">
                <Link to="/" className="nav-link">Home</Link>
                <Link to="/stats" className="nav-link">Stats</Link>
            </nav>
        </div>
    );
}

export default Chatbot;
