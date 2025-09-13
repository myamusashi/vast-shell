import QtQuick

import qs.Data
import qs.Components

Rectangle {
	id: root

	color: "transparent"
	required property real value
	required property string text
	required property real size

	property real textPadding: 20
	property real minSize: 120 + size

	TextMetrics {
		id: textMetrics
		text: root.text
		font.pixelSize: textStatus.font.pixelSize
		font.bold: textStatus.font.bold
	}

	width: Math.max(minSize, Math.max(textMetrics.width, textMetrics.height) + textPadding * 4)
	height: width

	Canvas {
		id: canvas
		anchors.fill: parent
		onPaint: {
			var ctx = getContext("2d");
			var centerX = width / 2;
			var centerY = height / 2;
			var radius = Math.min(width, height) / 2 - 10;

			ctx.clearRect(0, 0, width, height);

			ctx.beginPath();
			ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
			ctx.strokeStyle = Appearance.colors.on_primary;
			ctx.lineWidth = 8;
			ctx.stroke();

			ctx.beginPath();
			var startAngle = -Math.PI / 2;
			var endAngle = startAngle + (root.value / 100) * 2 * Math.PI;
			ctx.arc(centerX, centerY, radius, startAngle, endAngle);
			ctx.strokeStyle = root.value > 80 ? Appearance.colors.on_error : root.value > 60 ? Appearance.colors.tertiary : Appearance.colors.primary;
			ctx.lineWidth = 8;
			ctx.lineCap = "round";
			ctx.stroke();
		}
	}

	Timer {
		id: updateTimer
		interval: 50
		repeat: true
		running: true
		onTriggered: {
			canvas.requestPaint();
		}
	}

	StyledText {
		id: textStatus
		anchors.centerIn: parent
		text: root.text
		font.pixelSize: Math.max(12, Math.min(24, root.width / 6))
		font.bold: true
		color: Appearance.colors.on_surface
		horizontalAlignment: Text.AlignHCenter
		verticalAlignment: Text.AlignVCenter
		wrapMode: Text.WordWrap
		width: parent.width - root.textPadding * 2
	}
}
