document.addEventListener("DOMContentLoaded", function () {
    console.log("🚀 SEO Dashboard Loaded");

    // Initialize grid using GridStack
    const grid = GridStack.init({
        cellHeight: 120,
        verticalMargin: 10,
        animate: true,
        resizable: { handles: "se, sw, ne, nw" }
    });

    // Reset grid layout when the reset button is clicked
    document.getElementById("resetButton").addEventListener("click", function () {
        localStorage.removeItem("grid-stack-layout");
        location.reload();
    });

    // Global storage for chart instances for later updates
    window.charts = {};

    /**
     * Creates a chart on the given canvas, stores the Chart.js instance for future updates.
     *
     * @param {string} canvasId - The id of the canvas element.
     * @param {string} statKey - The key associated with this chart data (used as an identifier).
     * @param {string} type - The type of chart ("bar" or "line").
     * @param {Object} data - The data object to display.
     * @param {Array} colors - An array of colors for the chart.
     */
    function createChart(canvasId, statKey, type, data, colors) {
        const canvas = document.getElementById(canvasId);
        if (!canvas) return;

        // Adjust canvas dimensions based on its parent container
        canvas.width = canvas.parentElement.clientWidth;
        canvas.height = canvas.parentElement.clientHeight - 40;

        const ctx = canvas.getContext("2d");
        const chartInstance = new Chart(ctx, {
            type: type,
            data: {
                labels: Array(Object.keys(data).length).fill(""), // Remove x-axis labels
                datasets: [{
                    label: "",
                    data: Object.values(data),
                    backgroundColor: colors,
                    borderColor: colors.map(c => c.replace(/0.2/, "1.0")),
                    borderWidth: 1
                }]
            },
            options: {
                plugins: {
                    legend: {
                        display: true,
                        position: "top",
                        labels: {
                            usePointStyle: true,
                            boxWidth: 12,
                            generateLabels: function (chart) {
                                return chart.data.labels.map((_, index) => ({
                                    text: "", // Hide text in legend
                                    fillStyle: chart.data.datasets[0].backgroundColor[index],
                                    hidden: false,
                                    datasetIndex: 0,
                                    index: index
                                }));
                            }
                        },
                        onHover: function (event, legendItem) {
                            const tooltip = document.getElementById("legendTooltip");
                            if (!tooltip) return;
                            if (legendItem && seoUrls[legendItem.index]) {
                                tooltip.innerText = seoUrls[legendItem.index];
                                tooltip.style.opacity = 1;
                                tooltip.style.left = `${event.native.clientX + 10}px`;
                                tooltip.style.top = `${event.native.clientY + 10}px`;
                            }
                        },
                        onLeave: function () {
                            const tooltip = document.getElementById("legendTooltip");
                            if (tooltip) {
                                tooltip.style.opacity = 0;
                            }
                        }
                    },
                    tooltip: {
                        callbacks: {
                            label: function (tooltipItem) {
                                return `${seoUrls[tooltipItem.dataIndex]}: ${tooltipItem.raw}`;
                            }
                        }
                    }
                },
                maintainAspectRatio: false,
                responsive: true,
                scales: {
                    x: { display: false } // Remove x-axis completely
                }
            }
        });

        // Save the chart instance using the statKey as an identifier
        window.charts[statKey] = chartInstance;
    }

    // Create tooltip div for legend hover effect
    const tooltipDiv = document.createElement("div");
    tooltipDiv.id = "legendTooltip";
    tooltipDiv.style.position = "absolute";
    tooltipDiv.style.background = "rgba(0, 0, 0, 0.8)";
    tooltipDiv.style.color = "#fff";
    tooltipDiv.style.padding = "5px 10px";
    tooltipDiv.style.borderRadius = "5px";
    tooltipDiv.style.opacity = "0";
    tooltipDiv.style.pointerEvents = "none";
    tooltipDiv.style.transition = "opacity 0.2s ease";
    document.body.appendChild(tooltipDiv);

    // Generate charts using initial seoStats object.
    // Assumes that global objects `seoStats`, `seoUrls`, and `colors` are defined.
    Object.keys(seoStats).forEach((stat, index) => {
        const id = `${stat.replace(/\s+/g, "_").toLowerCase()}Chart`;
        const chartType = index % 2 === 0 ? "bar" : "line"; // Alternate chart types
        createChart(id, stat, chartType, seoStats[stat], colors);
    });

    /**
     * Updates each chart with new data.
     *
     * @param {Object} newData - New SEO data object returned from the Sinatra endpoint.
     */
    function updateCharts(newData) {
        // Loop through each stat in the new data object
        Object.keys(newData).forEach(stat => {
            if (window.charts[stat]) {
                const chart = window.charts[stat];
                // Update the chart dataset values and labels
                chart.data.datasets[0].data = Object.values(newData[stat]);
                chart.data.labels = Array(Object.keys(newData[stat]).length).fill("");
                chart.update();
            }
        });
    }

    // Polling mechanism: fetch new SEO data from the Sinatra endpoint every 10 seconds
    setInterval(() => {
        fetch("/seo_data.json")
            .then(response => response.json())
            .then(newData => {
                updateCharts(newData);
            })
            .catch(error => console.error("Error fetching SEO data:", error));
    }, 10000);
});
