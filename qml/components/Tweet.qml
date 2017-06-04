/*
    Copyright (C) 2017 Sebastian J. Wolf

    This file is part of Piepmatz.

    Piepmatz is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Piepmatz is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Piepmatz. If not, see <http://www.gnu.org/licenses/>.
*/
import QtQuick 2.0
import QtGraphicalEffects 1.0
import Sailfish.Silica 1.0
import "../pages"
import "../js/functions.js" as Functions

ListItem {

    id: singleTweet

    property variant tweetModel;
    property string tweetId : ( tweetModel.retweeted_status ? tweetModel.retweeted_status.id_str : tweetModel.id_str );
    // TODO: attributes favorited and retweeted are only temporary workarounds until we are able to update and replace individual tweets in the model
    // does not work completely if model is reloaded (e.g. during scrolling)
    property bool favorited : ( tweetModel.retweeted_status ? tweetModel.retweeted_status.favorited : tweetModel.favorited );
    property bool retweeted : ( tweetModel.retweeted_status ? tweetModel.retweeted_status.retweeted : tweetModel.retweeted );
    property string embeddedTweetId;
    property variant embeddedTweet;
    property bool hasEmbeddedTweet : false;
    property string referenceUrl;
    property variant referenceMetadata;
    property bool hasReference : false;

    contentHeight: tweetRow.height + tweetAdditionalRow.height + tweetSeparator.height + 3 * Theme.paddingMedium
    contentWidth: parent.width

    menu: ContextMenu {
        MenuItem {
            onClicked: {
                pageStack.push(Qt.resolvedUrl("../pages/NewTweetPage.qml"), {"replyToStatusId": singleTweet.tweetId});
            }
            text: qsTr("Reply to Tweet")
        }
        MenuItem {
            onClicked: {
                pageStack.push(Qt.resolvedUrl("../pages/NewTweetPage.qml"), {"attachmentTweet": tweetModel});
            }
            text: qsTr("Retweet with Comment")
        }
        MenuItem {
            onClicked: {
                Qt.openUrlExternally(Functions.getTweetUrl(tweetModel));
            }
            text: qsTr("Open in Browser")
        }
    }

    Column {
        id: tweetColumn
        width: parent.width - ( 2 * Theme.horizontalPageMargin )
        spacing: Theme.paddingSmall
        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
        }

        Row {
            id: tweetRow
            width: parent.width
            spacing: Theme.paddingMedium

            Column {
                id: tweetAuthorColumn
                width: parent.width / 6
                height: parent.width / 6
                spacing: Theme.paddingSmall
                Image {
                    id: tweetRetweetedImage
                    source: "image://theme/icon-s-retweet"
                    visible: tweetModel.retweeted_status ? true : false
                    anchors.right: parent.right
                    width: Theme.fontSizeExtraSmall
                    height: Theme.fontSizeExtraSmall
                }
                Image {
                    id: tweetInReplyToImage
                    source: "image://theme/icon-s-repost"
                    visible: tweetModel.in_reply_to_user_id_str ? true : false
                    anchors.right: parent.right
                    width: Theme.fontSizeExtraSmall
                    height: Theme.fontSizeExtraSmall
                }

                Item {
                    id: tweetAuthorItem
                    width: parent.width
                    height: parent.width

                    Image {
                        id: tweetAuthorPicture
                        z: 42
                        source: Functions.findBiggerImage(tweetModel.retweeted_status ? tweetModel.retweeted_status.user.profile_image_url_https : tweetModel.user.profile_image_url_https )
                        width: parent.width
                        height: parent.height
                        sourceSize {
                            width: parent.width
                            height: parent.height
                        }
                        visible: false
                    }

                    Rectangle {
                        id: tweetAuthorPictureMask
                        z: 42
                        width: parent.width
                        height: parent.height
                        color: Theme.primaryColor
                        radius: parent.width / 7
                        visible: false
                    }

                    OpacityMask {
                        id: maskedTweetAuthorPicture
                        z: 42
                        source: tweetAuthorPicture
                        maskSource: tweetAuthorPictureMask
                        anchors.fill: tweetAuthorPicture
                        visible: tweetAuthorPicture.status === Image.Ready ? true : false
                        opacity: tweetAuthorPicture.status === Image.Ready ? 1 : 0
                        Behavior on opacity { NumberAnimation {} }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                pageStack.push(Qt.resolvedUrl("../pages/ProfilePage.qml"), {"profileModel": tweetModel.retweeted_status ? tweetModel.retweeted_status.user : tweetModel.user});
                            }
                        }
                    }

                    ImageProgressIndicator {
                        image: tweetAuthorPicture
                        withPercentage: false
                    }

                }
            }

            Column {
                id: tweetContentColumn
                width: parent.width * 5 / 6 - Theme.horizontalPageMargin

                spacing: Theme.paddingSmall

                Column {
                    Text {
                        id: tweetRetweetedText
                        font.pixelSize: Theme.fontSizeTiny
                        color: Theme.secondaryColor
                        text: qsTr("Retweeted by %1").arg(tweetModel.user.name)
                        visible: tweetModel.retweeted_status ? true : false
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                pageStack.push(Qt.resolvedUrl("../pages/ProfilePage.qml"), {"profileModel": tweetModel.user});

                            }
                        }
                    }

                    Text {
                        id: tweetInReplyToText
                        font.pixelSize: Theme.fontSizeTiny
                        color: Theme.secondaryColor
                        text: qsTr("In reply to %1").arg(Functions.getUserNameById(tweetModel.in_reply_to_user_id, tweetModel.user, tweetModel.entities.user_mentions))
                        visible: tweetModel.in_reply_to_user_id_str ? true : false
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                pageStack.push(Qt.resolvedUrl("../pages/ProfilePage.qml"), {"profileName": Functions.getScreenNameById(tweetModel.in_reply_to_user_id, tweetModel.user, tweetModel.entities.user_mentions)});
                            }
                        }
                    }
                }

                TweetUser {
                    id: tweetUserRow
                    tweetUser: tweetModel.retweeted_status ? tweetModel.retweeted_status.user : tweetModel.user
                }

                TweetText {
                    id: tweetContentText
                    tweet: tweetModel
                }

                Connections {
                    target: twitterApi
                    onGetOpenGraphSuccessful: {
                        if (referenceUrl === result.url) {
                            singleTweet.referenceMetadata = result;
                            singleTweet.hasReference = true;
                        }
                    }
                }

                Component {
                    id: openGraphComponent
                    Column {
                        spacing: Theme.paddingSmall
                        Separator {
                            width: parent.width
                            color: Theme.primaryColor
                            horizontalAlignment: Qt.AlignHCenter
                        }

                        Item {
                            id: openGraphImageItem
                            width: parent.width
                            height: parent.width * 2 / 3
                            visible: referenceMetadata.image ? true : false
                            Image {
                                id: openGraphImage

                                onStatusChanged: {
                                    if (status === Image.Error) {
                                        openGraphImageItem.visible = false;
                                    }
                                }

                                width: parent.width
                                height: parent.height
                                sourceSize {
                                    width: parent.width
                                    height: parent.height
                                }
                                fillMode: Image.PreserveAspectCrop
                                visible: status === Image.Ready ? true : false
                                opacity: status === Image.Ready ? 1 : 0
                                source: referenceMetadata.image ? referenceMetadata.image : ""
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (referenceMetadata.url) {
                                            Qt.openUrlExternally(referenceMetadata.url);
                                        }
                                    }
                                }
                            }
                            ImageProgressIndicator {
                                image: openGraphImage
                                withPercentage: false
                            }
                        }

                        Text {
                            visible: referenceMetadata.description ? true : false
                            width: parent.width
                            id: openGraphText
                            text: referenceMetadata.description ? referenceMetadata.description : ""
                            font.pixelSize: Theme.fontSizeTiny
                            color: Theme.primaryColor
                            wrapMode: Text.Wrap
                            textFormat: Text.StyledText
                            maximumLineCount: 4
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: referenceMetadata.url ? true : false
                            width: parent.width
                            id: openGraphLink
                            text: "<a href=\"" + referenceMetadata.url + "\">" + referenceMetadata.title + "</a>"
                            font.pixelSize: Theme.fontSizeTiny
                            color: Theme.secondaryColor
                            wrapMode: Text.Wrap
                            textFormat: Text.StyledText
                            onLinkActivated: {
                                Functions.handleLink(link);
                            }
                            linkColor: Theme.highlightColor
                        }

                        Separator {
                            width: parent.width
                            color: Theme.primaryColor
                            horizontalAlignment: Qt.AlignHCenter
                        }
                    }
                }

                Loader {
                    id: openGraphLoader
                    active: singleTweet.hasReference
                    width: parent.width
                    sourceComponent: openGraphComponent
                }

                Row {
                    id: tweetInfoRow
                    width: parent.width
                    spacing: Theme.paddingSmall

                    Connections {
                        target: twitterApi
                        onFavoriteSuccessful: {
                            if (singleTweet.tweetId === result.id_str) {
                                tweetFavoritesCountImage.source = "image://theme/icon-s-favorite?" + Theme.highlightColor;
                                tweetFavoritesCountText.color = Theme.highlightColor;
                                tweetFavoritesCountText.text = result.retweeted_status ? ( result.retweeted_status.favorite_count ? result.retweeted_status.favorite_count : " " ) : ( result.favorite_count ? result.favorite_count : " " );
                                singleTweet.favorited = true;
                            }
                        }
                        onUnfavoriteSuccessful: {
                            if (singleTweet.tweetId === result.id_str) {
                                tweetFavoritesCountImage.source = "image://theme/icon-s-favorite?" + Theme.primaryColor;
                                tweetFavoritesCountText.color = Theme.secondaryColor;
                                tweetFavoritesCountText.text = result.retweeted_status ? ( result.retweeted_status.favorite_count ? result.retweeted_status.favorite_count : " " ) : ( result.favorite_count ? result.favorite_count : " " );
                                singleTweet.favorited = false;
                            }
                        }
                        onRetweetSuccessful: {
                            if (singleTweet.tweetId === result.retweeted_status.id_str) {
                                tweetRetweetedCountImage.source = "image://theme/icon-s-retweet?" + Theme.highlightColor;
                                tweetRetweetedCountText.color = Theme.highlightColor;
                                tweetRetweetedCountText.text = result.retweeted_status ? ( result.retweeted_status.retweet_count ? result.retweeted_status.retweet_count : " " ) : ( result.retweet_count ? result.retweet_count : " " );
                                singleTweet.retweeted = true;
                            }
                        }
                        onUnretweetSuccessful: {
                            if (singleTweet.tweetId === result.id_str) {
                                tweetRetweetedCountImage.source = "image://theme/icon-s-retweet?" + Theme.primaryColor;
                                tweetRetweetedCountText.color = Theme.secondaryColor;
                                tweetRetweetedCountText.text = result.retweeted_status ? ( result.retweeted_status.retweet_count ? result.retweeted_status.retweet_count : " " ) : ( result.retweet_count ? result.retweet_count : " " );
                                singleTweet.retweeted = false;
                            }
                        }
                    }

                    Timer {
                        id: tweetDateUpdater
                        interval: 60000
                        running: true
                        repeat: true
                        onTriggered: {
                            tweetDateText.text = Format.formatDate(Functions.getValidDate(tweetModel.retweeted_status ? tweetModel.retweeted_status.created_at : tweetModel.created_at), Formatter.DurationElapsed);
                        }
                    }

                    Row {
                        width: parent.width * 9 / 20
                        Text {
                            id: tweetDateText
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: Theme.secondaryColor
                            text:  Format.formatDate(Functions.getValidDate(tweetModel.retweeted_status ? tweetModel.retweeted_status.created_at : tweetModel.created_at), Formatter.DurationElapsed)
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                    }

                    Row {
                        width: parent.width * 11 / 20
                        spacing: Theme.paddingSmall
                        Column {
                            width: parent.width / 6
                            Image {
                                id: tweetRetweetedCountImage
                                anchors.right: parent.right
                                source: tweetModel.retweeted_status ? ( tweetModel.retweeted_status.retweeted ? ( "image://theme/icon-s-retweet?" + Theme.highlightColor ) : "image://theme/icon-s-retweet" ) : ( tweetModel.retweeted ? ( "image://theme/icon-s-retweet?" + Theme.highlightColor ) : "image://theme/icon-s-retweet" )
                                width: Theme.fontSizeSmall
                                height: Theme.fontSizeSmall
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: singleTweet.retweeted ? twitterApi.unretweet(singleTweet.tweetId) : twitterApi.retweet(singleTweet.tweetId)
                                }
                            }
                        }
                        Column {
                            width: parent.width / 3
                            Text {
                                id: tweetRetweetedCountText
                                font.pixelSize: Theme.fontSizeExtraSmall
                                anchors.left: parent.left
                                color: tweetModel.retweeted_status ? ( tweetModel.retweeted_status.retweeted ? Theme.highlightColor : Theme.secondaryColor ) : ( tweetModel.retweeted ? Theme.highlightColor : Theme.secondaryColor )
                                text: tweetModel.retweeted_status ? ( tweetModel.retweeted_status.retweet_count ? tweetModel.retweeted_status.retweet_count : " " ) : ( tweetModel.retweet_count ? tweetModel.retweet_count : " " )
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: singleTweet.retweeted ? twitterApi.unretweet(singleTweet.tweetId) : twitterApi.retweet(singleTweet.tweetId)
                                }
                            }
                        }
                        Column {
                            width: parent.width / 6
                            Image {
                                id: tweetFavoritesCountImage
                                anchors.right: parent.right
                                source: tweetModel.retweeted_status ? ( tweetModel.retweeted_status.favorited ? ( "image://theme/icon-s-favorite?" + Theme.highlightColor ) : "image://theme/icon-s-favorite" ) : ( tweetModel.favorited ? ( "image://theme/icon-s-favorite?" + Theme.highlightColor ) : "image://theme/icon-s-favorite" )
                                width: Theme.fontSizeSmall
                                height: Theme.fontSizeSmall
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: singleTweet.favorited ? twitterApi.unfavorite(singleTweet.tweetId) : twitterApi.favorite(singleTweet.tweetId)
                                }
                            }
                        }
                        Column {
                            width: parent.width / 3
                            Text {
                                id: tweetFavoritesCountText
                                font.pixelSize: Theme.fontSizeExtraSmall
                                anchors.left: parent.left
                                color: tweetModel.retweeted_status ? ( tweetModel.retweeted_status.favorited ? Theme.highlightColor : Theme.secondaryColor ) : ( tweetModel.favorited ? Theme.highlightColor : Theme.secondaryColor )
                                text: tweetModel.retweeted_status ? ( tweetModel.retweeted_status.favorite_count ? tweetModel.retweeted_status.favorite_count : " " ) : ( tweetModel.favorite_count ? tweetModel.favorite_count : " " )
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: singleTweet.favorited ? twitterApi.unfavorite(singleTweet.tweetId) : twitterApi.favorite(singleTweet.tweetId)
                                }
                            }
                        }
                    }
                }


            }
        }

        Row {
            id: tweetAdditionalRow
            width: parent.width
            spacing: Theme.paddingMedium

            Column {
                id: dummyLeftColumn
                width: parent.width / 6
                height: Theme.fontSizeTiny
            }

            Column {
                id: tweetAdditionalRightColumn
                width: parent.width * 5 / 6 - Theme.horizontalPageMargin

                spacing: Theme.paddingSmall

                TweetImageSlideshow {
                    id: tweetImageSlideshow
                    visible: Functions.hasImage(tweetModel.retweeted_status ? tweetModel.retweeted_status : tweetModel)
                    tweet: tweetModel
                }

                Loader {
                    id: videoLoader
                    active: Functions.containsVideo(tweetModel.retweeted_status ? tweetModel.retweeted_status : tweetModel)
                    width: parent.width
                    height: Functions.getVideoHeight(parent.width, tweetModel.retweeted_status ? tweetModel.retweeted_status : tweetModel)
                    sourceComponent: tweetVideoComponent
                }

                Component {
                    id: tweetVideoComponent
                    TweetVideo {
                        tweet: tweetModel
                    }
                }

                Connections {
                    target: twitterApi
                    onShowStatusSuccessful: {
                        if (embeddedTweetId === result.id_str) {
                            embeddedTweet = result;
                            hasEmbeddedTweet = true;
                        }
                    }
                }

                Component {
                    id: embeddedTweetComponent
                    EmbeddedTweet {
                        id: embeddedTweetItem
                        tweetModel: embeddedTweet
                        visible: hasEmbeddedTweet
                    }
                }

                Loader {
                    id: embeddedTweetLoader
                    active: hasEmbeddedTweet
                    width: parent.width
                    sourceComponent: embeddedTweetComponent
                }
            }
        }
    }

    Separator {
        id: tweetSeparator

        anchors {
            top: tweetColumn.bottom
            topMargin: Theme.paddingMedium
        }

        width: parent.width
        color: Theme.primaryColor
        horizontalAlignment: Qt.AlignHCenter
    }


}
