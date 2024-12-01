import React, { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import "./Chatbot.css";

const FASTAPI_API = "http://localhost:8000"; // Ensure correct URL

function Chatbot() {
    const [question, setQuestion] = useState(""); // State to store the input question
    const [selectedStock, setSelectedStock] = useState(""); // State to store the selected stock
    const [stockData, setStockData] = useState([]); // State to store fetched stock data
    const [filteredStockData, setFilteredStockData] = useState([]); // State to store filtered data (as an array)
    const [isLoading, setIsLoading] = useState(false); // State to handle loading state
    const [combinedData, setCombinedData] = useState(""); // State to store the combined string of stock data and user question
    const [llmResponse, setLlmResponse] = useState(""); // State to store LLM response
    const [isSubmitting, setIsSubmitting] = useState(false); // State to handle the submission state

    // List of stocks for the dropdown
    const stockOptions = [
        'Air Link Commun',
        'Avanceon Ltd',
        'Supernet Ltd.XB',
        'Hallmark',
        'Hum Network',
        'Media Times Ltd',
        'Netsol Tech.',
        'Octopus Digital',
        'Pak DatacomXD',
        'P.T.C.L.',
        'Symmetry Group',
        'Systems Limited',
        'Telecard',
        'TPL Corp Ltd',
        'TPL Trakker Ltd',
        'TRG Pak Ltd',
        'WorldCall'
    ];

    // Fetch data for stocks when the component mounts
    useEffect(() => {
        const FASTAPI_API = "localhost:8000"; // Do not add 'http://' here

        const fetchData = async () => {
            try {
                setIsLoading(true);
                const response = await fetch(`http://${FASTAPI_API}/getData`);
                if (response.ok) {
                    const data = await response.json();
                    setStockData(data.data); // Store the received data
                } else {
                    console.error("Failed to fetch stock data.");
                }
            } catch (error) {
                console.error("Error fetching data:", error);
            } finally {
                setIsLoading(false);
            }
        };


                fetchData();
            }, []);

    // Filter stock data whenever the selected stock changes
    useEffect(() => {
        if (selectedStock) {
            const filteredData = stockData.filter(
                (stock) => stock.company_name === selectedStock
            );
            setFilteredStockData(filteredData);
        } else {
            setFilteredStockData([]);
        }
    }, [selectedStock, stockData]);

    // Combine stock data and user question into a string
    const combineData = () => {
        let stockDataString = "Stock Data:\n";
        if (filteredStockData.length > 0) {
            filteredStockData
                .sort((a, b) => new Date(b.date) - new Date(a.date))
                .forEach((data) => {
                    stockDataString += `Date: ${data.date}, Turnover: ${data.turnover}, Previous Rate: ${data.prev_rate}, Open Rate: ${data.open_rate}, Last Rate: ${data.last_rate}, Highest Rate: ${data.highest_rate}, Lowest Rate: ${data.lowest_rate}\n`;
                });
        } else {
            stockDataString += "No stock data available.\n";
        }

        stockDataString += `User Question: ${question}\n`;
        setCombinedData(stockDataString);
    };

    // Handle submit button click
    const handleSubmit = async () => {
        if (!selectedStock || !question.trim()) {
            alert("Please select a stock and enter a question.");
            return;
        }
        combineData(); // Combine data when the submit button is clicked
        setIsSubmitting(true);

        try {
            const response = await fetch(`${FASTAPI_API}/ask_llm`, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                body: JSON.stringify({
                    user_prompt: question,
                    stock_data: combinedData,
                }),
            });

            if (response.ok) {
                const data = await response.json();
                setLlmResponse(data.llm_response); // Store LLM response in state
            } else {
                console.error("Failed to get LLM response.");
            }
        } catch (error) {
            console.error("Error sending data to LLM:", error);
        } finally {
            setIsSubmitting(false);
        }
    };

    return (
        <div className="chatbot-container">
            <h1>Welcome to our AI-powered Chatbot!</h1>
            <p className="subheading">You can ask questions and get predictions about stocks.</p>

            <nav className="nav-bar">
                <Link to="/" className="nav-link">Home</Link>
                <Link to="/stats" className="nav-link">Stats</Link>
            </nav>

            {/* Input Section */}
            <div className="input-section">
                <label htmlFor="stock-select" className="dropdown-label">
                    Select a stock:
                </label>
                <select
                    id="stock-select"
                    value={selectedStock}
                    onChange={(e) => setSelectedStock(e.target.value)}
                    className="dropdown"
                >
                    <option value="">--Choose a stock--</option>
                    {stockOptions.map((stock) => (
                        <option key={stock} value={stock}>
                            {stock}
                        </option>
                    ))}
                </select>

                <label htmlFor="question-input" className="input-label">
                    Your Question:
                </label>
                <input
                    id="question-input"
                    type="text"
                    value={question}
                    onChange={(e) => setQuestion(e.target.value)}
                    placeholder="Type your question here..."
                    className="text-input"
                />
            </div>

            {/* Show Filtered Data */}
            {isLoading ? (
                <p>Loading stock data...</p>
            ) : filteredStockData.length > 0 ? (
                <div className="stock-details">
                    <h2>Stock Details for {selectedStock}</h2>
                    {filteredStockData
                        .sort((a, b) => new Date(b.date) - new Date(a.date))
                        .slice(0, 1)
                        .map((data, index) => (
                            <div key={index} className="stock-item">
                                <p>Date: {data.date}</p>
                                <p>Turnover: {data.turnover}</p>
                                <p>Previous Rate: {data.prev_rate}</p>
                                <p>Open Rate: {data.open_rate}</p>
                                <p>Last Rate: {data.last_rate}</p>
                                <p>Highest Rate: {data.highest_rate}</p>
                                <p>Lowest Rate: {data.lowest_rate}</p>
                            </div>
                        ))}
                </div>
            ) : (
                selectedStock && <p>No data found for {selectedStock}.</p>
            )}

            {/* Submit Button */}
            <button
                className="submit-button"
                onClick={handleSubmit} 
                disabled={isSubmitting} // Disable button while submitting
            >
                {isSubmitting ? "Submitting..." : "Submit"}
            </button>

            {/* Display LLM Response */}
            {llmResponse && (
                <div className="llm-response">
                    <h2>LLM Response:</h2>
                    <p>{llmResponse}</p>
                </div>
            )}
        </div>
    );
}

export default Chatbot;
