import QtQuick

// Sparkline.qml — a smooth filled line chart drawn on a canvas.
// Used for the battery discharge history. Only repaints when the data or the
// size actually changes.
Item {
	id: root

	property var points: []          // [{ t, pct }]
	property real minValue: 0
	property real maxValue: 100
	property color lineColor: Theme.accent
	property color fillColor: Theme.accentGhost
	property color gridColor: Theme.alpha(Theme.outline, 0.18)
	property int gridLines: 3

	onPointsChanged: canvas.requestPaint()
	onMinValueChanged: canvas.requestPaint()
	onMaxValueChanged: canvas.requestPaint()
	onLineColorChanged: canvas.requestPaint()

	Canvas {
		id: canvas

		anchors.fill: parent
		renderStrategy: Canvas.Cooperative

		onWidthChanged: requestPaint()
		onHeightChanged: requestPaint()

		onPaint: {
			const ctx = getContext("2d");
			ctx.clearRect(0, 0, width, height);

			const pad = 5;
			const plotW = width;
			const plotH = height - pad * 2;

			// horizontal guides
			ctx.strokeStyle = root.gridColor;
			ctx.lineWidth = 1;
			for (let g = 0; g <= root.gridLines; g++) {
				const y = pad + plotH * g / root.gridLines;
				ctx.beginPath();
				ctx.moveTo(0, y);
				ctx.lineTo(plotW, y);
				ctx.stroke();
			}

			const data = root.points;
			if (data.length < 2) return;

			let lo = root.minValue;
			let hi = root.maxValue;
			if (hi - lo < 0.5) hi = lo + 0.5;

			const xy = [];
			for (let i = 0; i < data.length; i++) {
				const x = plotW * i / (data.length - 1);
				const norm = (data[i].pct - lo) / (hi - lo);
				const y = pad + plotH * (1 - Math.max(0, Math.min(1, norm)));
				xy.push({ x: x, y: y });
			}

			// smooth the polyline with midpoints
			ctx.beginPath();
			ctx.moveTo(xy[0].x, xy[0].y);
			for (let i = 1; i < xy.length; i++) {
				const prev = xy[i - 1];
				const cur = xy[i];
				const mx = (prev.x + cur.x) / 2;
				const my = (prev.y + cur.y) / 2;
				ctx.quadraticCurveTo(prev.x, prev.y, mx, my);
			}
			ctx.lineTo(xy[xy.length - 1].x, xy[xy.length - 1].y);

			const strokePath = ctx;

			// fill under the curve
			const fill = ctx.createLinearGradient(0, 0, 0, height);
			fill.addColorStop(0, root.fillColor);
			fill.addColorStop(1, "transparent");

			ctx.save();
			ctx.lineTo(plotW, height);
			ctx.lineTo(0, height);
			ctx.closePath();
			ctx.fillStyle = fill;
			ctx.fill();
			ctx.restore();

			// the line itself, redrawn on top of the fill
			ctx.beginPath();
			ctx.moveTo(xy[0].x, xy[0].y);
			for (let i = 1; i < xy.length; i++) {
				const prev = xy[i - 1];
				const cur = xy[i];
				ctx.quadraticCurveTo(prev.x, prev.y, (prev.x + cur.x) / 2, (prev.y + cur.y) / 2);
			}
			ctx.lineTo(xy[xy.length - 1].x, xy[xy.length - 1].y);

			ctx.strokeStyle = root.lineColor;
			ctx.lineWidth = 2;
			ctx.lineJoin = "round";
			ctx.lineCap = "round";
			ctx.stroke();

			// a dot on the newest sample
			const last = xy[xy.length - 1];
			ctx.beginPath();
			ctx.arc(last.x, last.y, 3, 0, Math.PI * 2);
			ctx.fillStyle = root.lineColor;
			ctx.fill();
		}
	}
}
