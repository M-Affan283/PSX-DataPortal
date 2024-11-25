import React, { useState, useEffect, useCallback, useRef } from "react";
import { Link } from "react-router-dom";
import {Chart as ChartJS, CategoryScale, LinearScale, RadialLinearScale, BarElement, LineElement, PointElement, Title, Tooltip, Legend, ArcElement} from "chart.js";
import { Bar, Line, PolarArea } from "react-chartjs-2";
import "./Stats.css";

// Register all necessary Chart.js components
ChartJS.register(
    CategoryScale,
    LinearScale,
    RadialLinearScale, 
    BarElement,
    LineElement,
    PointElement,
    Title,
    Tooltip,
    Legend,
    ArcElement
);

function Stats() {
    const [chartData, setChartData] = useState([]);
    const [isLoading, setIsLoading] = useState(false);
    const dataFetchedRef = useRef(false);

    const graphTypes = {
        turnover: Bar,
        prev_rate: Line,
        open_rate: Line,
        highest_rate: Line,
        lowest_rate: Line,
        last_rate: Line,
        difference: PolarArea,
    };

    const graphColors = {
        turnover: "rgba(75, 192, 192, 0.5)",
        prev_rate: "rgba(54, 162, 235, 0.5)",
        open_rate: "rgba(153, 102, 255, 0.5)",
        highest_rate: "rgba(255, 206, 86, 0.5)",
        lowest_rate: "rgba(255, 99, 132, 0.5)",
        last_rate: "rgba(75, 192, 192, 0.5)",
        difference: ["rgba(255, 99, 132, 0.5)", "rgba(54, 162, 235, 0.5)"],
    };

    const processChartData = useCallback((data) => {
        const parameters = ["turnover", "prev_rate", "open_rate", "highest_rate", "lowest_rate", "last_rate", "difference"];
        const processedData = parameters.map((param) => {
            const labels = data.map((item) => item.company_name);
            const values = data.map((item) => item[param]);

            const color = Array.isArray(graphColors[param]) ? graphColors[param][0] : graphColors[param];
            const borderColor = typeof color === "string" ? color.replace("0.5", "1") : "rgba(0, 0, 0, 1)";

            return {
                parameter: param,
                labels,
                datasets: [
                    {
                        label: param,
                        data: values,
                        backgroundColor: color,
                        borderColor,
                        borderWidth: 1,
                    },
                ],
            };
        });
        setChartData(processedData);
    }, [graphColors]);

    useEffect(() => {
        if (dataFetchedRef.current) return;
        dataFetchedRef.current = true;

        const fetchData = async () => {
            try {
                setIsLoading(true);
                const response = await fetch("http://localhost:8000/getData");
                if (response.ok) {
                    const data = await response.json();
                    processChartData(data.data);
                } else {
                    console.error("Failed to fetch data.");
                }
            } catch (error) {
                console.error("Error:", error);
            } finally {
                setIsLoading(false);
            }
        };

        fetchData();
    }, [processChartData]);

    return (
        <div className="stats-container">
            <nav className="nav-bar">
                <Link to="/" className="nav-link">Home</Link>
                <Link to="/stats" className="nav-link">Stats</Link>
            </nav>
            <h1>Company Data Analysis</h1>
            {isLoading ? (
                <p>Loading data...</p>
            ) : chartData.length > 0 ? (
                chartData.map((chart, index) => {
                    const GraphComponent = graphTypes[chart.parameter];
                    return (
                        <div key={index} className="chart-section">
                            <h2>{chart.parameter.toUpperCase()} Graph</h2>
                            <GraphComponent
                                data={chart}
                                options={{
                                    responsive: true,
                                    plugins: {
                                        legend: { position: "top" },
                                        title: {
                                            display: true,
                                            text: `Graph for ${chart.parameter}`,
                                        },
                                    },
                                }}
                            />
                        </div>
                    );
                })
            ) : (
                <p>No data available to display.</p>
            )}
        </div>
    );
}

export default Stats;
