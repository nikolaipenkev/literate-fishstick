document.addEventListener("DOMContentLoaded", function () {
    console.log("DOM fully loaded and parsed.");

    // Initialize GridStack
    const grid = GridStack.init({
        cellHeight: 100,
        verticalMargin: 10,
        animate: true
    });

    document.getElementById("resetButton").addEventListener("click", function () {
        localStorage.removeItem("grid-stack-layout");
        location.reload();
    });

    // Chart.js Helper Functions
    function createChart(canvasId, type, data, colors) {
        const canvas = document.getElementById(canvasId);
        if (!canvas) {
            console.warn(`Canvas ${canvasId} not found`);
            return;
        }

        const ctx = canvas.getContext("2d");
        new Chart(ctx, {
            type: type,
            data: {
                labels: Object.keys(data),
                datasets: [{
                    data: Object.values(data),
                    backgroundColor: colors
                }]
            },
            options: {
                plugins: { legend: { display: true } },
                maintainAspectRatio: false,
                responsive: true
            }
        });
    }

    if (!seoStats) {
        console.error("🚨 No SEO stats found. Skipping chart generation.");
        return;
    }

    console.log("Aggregated SEO Stats:", seoStats);

    // Generate a chart for each stat
    Object.keys(seoStats).forEach(stat => {
        const value = seoStats[stat] || 0;
        const id = `${stat.replace(/\s+/g, "_").toLowerCase()}Chart`;

        let chartType = "bar";
        let colors = ["#36a2eb"];

        if (stat.includes("Usage") || stat.includes("Presence")) {
            chartType = "pie";
            colors = ["#66bb6a", "#e0e0e0"];
        } else if (stat.includes("Word") || stat.includes("Title") || stat.includes("Page Size")) {
            chartType = "bar";
            colors = ["#4bc0c0"];
        } else {
            chartType = "doughnut";
            colors = ["#ff4081"];
        }

        createChart(id, chartType, { [stat]: value, "Other": 100 - value }, colors);
    });
});
