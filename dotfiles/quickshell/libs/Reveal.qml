import QtQuick

QtObject {
    id: reveal

    property real progress: 0
    readonly property bool hiding: lower.running

    signal hidden

    function show() {
        lower.stop();
        raise.start();
    }

    function hide() {
        raise.stop();
        lower.start();
    }

    property NumberAnimation raise: SpatialAnimation {
        target: reveal
        property: "progress"
        to: 1
        duration: Theme.animation.expressive.spatial.fastDuration
    }

    property NumberAnimation lower: NumberAnimation {
        target: reveal
        property: "progress"
        to: 0
        duration: Theme.durationDefault
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Theme.curveEmphasizedAccelerate
    }

    property Connections completion: Connections {
        target: reveal.lower

        function onFinished() {
            reveal.hidden();
        }
    }
}
