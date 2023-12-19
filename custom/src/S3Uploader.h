#pragma once

#include <QObject>

class S3Uploader : public QObject
{
    Q_OBJECT

public:
    void init();
    Q_INVOKABLE int upload();
};
