document.addEventListener("DOMContentLoaded", function () {
    console.log("🚀 SEO Dashboard Loaded");

    const grid = GridStack.init({
        cellHeight: 120,
        verticalMargin: 10,
        animate: true,
        resizable: { handles: "se, sw, ne, nw" }
    });

    document.getElementById("resetButton").addEventListener("click", function () {
        localStorage.removeItem("grid-stack-layout");
        location.reload();
    });

    function createChart(canvasId, type, data, colors) {
        const canvas = document.getElementById(canvasId);
        if (!canvas) return;

        canvas.width = canvas.parentElement.clientWidth;
        canvas.height = canvas.parentElement.clientHeight - 40;

        const ctx = canvas.getContext("2d");
        new Chart(ctx, {
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
                            generateLabels: function(chart) {
                                return chart.data.labels.map((_, index) => ({
                                    text: "", // Hide text in legend
                                    fillStyle: chart.data.datasets[0].backgroundColor[index],
                                    hidden: false,
                                    datasetIndex: 0,
                                    index: index
                                }));
                            }
                        },
                        onHover: function(event, legendItem) {
                            const tooltip = document.getElementById("legendTooltip");
                            if (!tooltip) return;

                            if (legendItem && seoUrls[legendItem.index]) {
                                tooltip.innerText = seoUrls[legendItem.index];
                                tooltip.style.opacity = 1;
                                tooltip.style.left = `${event.native.clientX + 10}px`;
                                tooltip.style.top = `${event.native.clientY + 10}px`;
                            }
                        },
                        onLeave: function() {
                            const tooltip = document.getElementById("legendTooltip");
                            if (tooltip) {
                                tooltip.style.opacity = 0;
                            }
                        }
                    },
                    tooltip: {
                        callbacks: {
                            label: function(tooltipItem) {
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
    }


    // Add tooltip div for legend hover effect
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

    // Generate charts
    Object.keys(seoStats).forEach((stat, index) => {
        const id = `${stat.replace(/\s+/g, "_").toLowerCase()}Chart`;
        const chartType = index % 2 === 0 ? "bar" : "line"; // Alternate bar/line charts
        createChart(id, chartType, seoStats[stat], colors);
    });
});
