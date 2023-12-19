/****************************************************************************
 *
 * (c) 2009-2019 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 *   @brief Custom QGCCorePlugin Implementation
 *   @author Gus Grubba <gus@auterion.com>
 */

#include <QtQml>
#include <QQmlEngine>
#include <QDateTime>
#include <QQmlEngine>

#include "CustomPlugin.h"
#include "S3Uploader.h"

#include "QGCApplication.h"


QGC_LOGGING_CATEGORY(CustomLog, "CustomLog")

CustomPlugin::CustomPlugin(QGCApplication *app, QGCToolbox *toolbox)
    : QGCCorePlugin(app, toolbox)
{
}

CustomPlugin::~CustomPlugin()
{
}


static QObject *s3UploadSingletonFactory(QQmlEngine *, QJSEngine*)
{
    qCDebug(CustomLog) << "Creating S3Uploader instance";
    S3Uploader *s3Uploader = new S3Uploader();
    auto *pPlug = qobject_cast<CustomPlugin *>(qgcApp()->toolbox()->corePlugin());
    if (pPlug)
    {
        s3Uploader->init();
    }
    else
    {
        qCritical() << "Error obtaining instance of CustomPlugin";
    }
    return s3Uploader;
}

void CustomPlugin::setToolbox(QGCToolbox *toolbox)
{
    QGCCorePlugin::setToolbox(toolbox);

    qmlRegisterSingletonType<S3Uploader>("S3Uploader", 1, 0, "S3Uploader", s3UploadSingletonFactory);
    // Allows us to be notified when the user goes in/out out advanced mode
    connect(qgcApp()->toolbox()->corePlugin(), &QGCCorePlugin::showAdvancedUIChanged, this, &CustomPlugin::_advancedChanged);
}

void CustomPlugin::_advancedChanged(bool changed)
{
    // Firmware Upgrade page is only show in Advanced mode
    // emit _options->showFirmwareUpgradeChanged(changed);
}
