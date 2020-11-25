import QtQuick 2.12
import QtQuick.Controls 2.12
import org.kde.kwin 2.0 as KWinComponents
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents

Item {
    id: clientItem

    property var client: model.client
    property int noBorderSpacing // Space to add between clientThumbnail and clientDecorations when client has no borders (mainly gtk csd or fullscreen windows)
    property bool ready: false

    property int clientX
    property int clientY
    property int clientWidth
    property int clientHeight
    
    ////////////////////////////
    // Grid view calculations //
    ////////////////////////////
    property int row: Math.floor(model.index / desktopItem.columns)
    property int column: model.index - desktopItem.columns * row

    property real clientGridScale: clientWidth / clientHeight > desktopItem.gridItemAspectRatio ?
            desktopItem.gridItemWidth / clientWidth :
            desktopItem.gridItemHeight / clientHeight
    property real gridX: clientsRepeater.count === 1 ?
            desktopItem.gridAreaX + (desktopItem.gridAreaWidth - gridWidth) / 2 :
            desktopItem.gridAreaX + column * desktopItem.gridItemWidth + (desktopItem.gridItemWidth - gridWidth) / 2
    property real gridY: clientsRepeater.count === 1 ?
            desktopItem.gridAreaY + (desktopItem.gridAreaHeight - gridHeight) / 2 :
            desktopItem.gridAreaY + row * desktopItem.gridItemHeight + (desktopItem.gridItemHeight - gridHeight) / 2
    property real gridWidth: clientWidth * clientGridScale
    property real gridHeight: clientHeight * clientGridScale
    ////////////////////////////

    states: [
        State {
            when: !ready // To animate when a new window is created
            PropertyChanges {
                target: clientItem
                x: desktopItem.gridAreaX
                y: desktopItem.gridAreaY
                width: 250
                height: 250
            }
        },
        State {
            when: !desktopItem.gridView && ready
            PropertyChanges {
                target: clientItem
                x: clientX
                y: clientY
                width: clientWidth
                height: clientHeight
            }
        },
        State {
            when: desktopItem.gridView && ready
            PropertyChanges {
                target: clientItem
                x: gridX
                y: gridY
                width: gridWidth
                height: gridHeight
            }
        }
    ]

    Behavior on x {
        enabled: mainWindow.activated
        NumberAnimation { duration: mainWindow.configAnimationsDuration; easing.type: mainWindow.easingType; }
    }

    Behavior on y {
        enabled: mainWindow.activated
        NumberAnimation { duration: mainWindow.configAnimationsDuration; easing.type: mainWindow.easingType; }
    }

    Behavior on width {
        enabled: mainWindow.activated
        NumberAnimation { duration: mainWindow.configAnimationsDuration; easing.type: mainWindow.easingType; }
    }

    Behavior on height {
        enabled: mainWindow.activated
        NumberAnimation { duration: mainWindow.configAnimationsDuration; easing.type: mainWindow.easingType; }
    }

    PlasmaCore.FrameSvgItem {
        id: selectedFrame
        anchors.fill: parent
        imagePath: "widgets/viewitem"
        prefix: "hover"
        visible: desktopItem.big && mainWindow.idle && mainWindow.selectedClientItem === clientItem
        opacity: 0.7
    }

    Row {
        id: clientDecorations
        x: (clientItem.gridWidth - clientDecorations.width) / 2 // Anchors are purposely avoided to centralize this because of animations
        y: desktopItem.clientsPadding
        visible: desktopItem.big && mainWindow.idle && mainWindow.configShowWindowTitles
        spacing: 10

        PlasmaCore.IconItem {
            id: icon
            height: mainWindow.clientsDecorationsHeight // PlasmaCore.Units.iconSizes.medium?
            width: height
            source: clientItem.client ? clientItem.client.icon : null
        }

        Text {
            id: caption
            height: mainWindow.clientsDecorationsHeight
            text: clientItem.client ? clientItem.client.caption : ""
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            color: "white"

            property real maxWidth: clientItem.gridWidth - 5 * icon.width

            onMaxWidthChanged: updateWidth();
            onTextChanged: updateWidth();

            function updateWidth() {
                caption.width = undefined;
                if (caption.width > caption.maxWidth) caption.width = caption.maxWidth;
            }
        }
    }

    PlasmaComponents.ToolButton {
        id: closeButton
        y: desktopItem.clientsPadding
        height: mainWindow.clientsDecorationsHeight
        width: height
        anchors.right: parent.right
        anchors.rightMargin: desktopItem.clientsPadding
        visible: selectedFrame.visible && mainWindow.configShowWindowTitles
        iconName: "window-close"
        flat: true

        onClicked: clientItem.client.closeWindow();
    }

    KWinComponents.ThumbnailItem {
        id: clientThumbnail
        anchors.fill: Drag.active ? undefined : parent // tried to change in the state, but doesn't work
        anchors.margins: desktopItem.clientsPadding + noBorderSpacing
        anchors.topMargin: desktopItem.big && mainWindow.configShowWindowTitles ?
                desktopItem.clientsPadding + noBorderSpacing + mainWindow.clientsDecorationsHeight :
                desktopItem.clientsPadding + noBorderSpacing
        Drag.source: clientItem.client
        wId: clientItem.client ? clientItem.client.internalId : "{00000000-0000-0000-0000-000000000000}"
        clip: true
        clipTo: screenItem

        states: State {
            when: clientThumbnail.Drag.active

            PropertyChanges {
                target: clientThumbnail
                x: clientDragHandler.centroid.position.x - clientThumbnail.width / 2
                y: clientDragHandler.centroid.position.y - clientThumbnail.height / 2
                width: 250; height: 250; clip: false
                Drag.hotSpot.x: clientThumbnail.width / 2
                Drag.hotSpot.y: clientThumbnail.height / 2
            }
        }
    }

    DragHandler {
        id: clientDragHandler
        target: null

        onActiveChanged: {
            mainWindow.dragging = active;
            active ? clientThumbnail.Drag.active = true : clientThumbnail.Drag.drop();
        }
    }

    Component.onCompleted: ready = true;

    onClientChanged: {
        if (!client) return;

        updateClientProperties();
        client.clientFinishUserMovedResized.connect(function(clientParam) { if (clientItem) updateClientProperties(); });
        client.clientMaximizedStateChanged.connect(function(clientParam, h, v) { if (clientItem) updateClientProperties(); });
    }

    // Update non-notifiable properties
    function updateClientProperties() {
        if (!client) return;

        clientX = client.x - screenItem.x;
        clientY = client.y - screenItem.y;
        clientWidth = client.width;
        clientHeight = client.height;

        noBorderSpacing = client.noBorder ? desktopItem.big ? 18 : 4 : 0;
    }
}