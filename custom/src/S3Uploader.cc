#define USE_IMPORT_EXPORT

#include <aws/core/Aws.h>
#include <aws/core/auth/AWSCredentialsProviderChain.h>
#include <aws/core/client/ClientConfiguration.h>
#include <aws/sts/STSClient.h>
#include <aws/s3/S3Client.h>
#include <aws/s3/model/ListObjectsV2Request.h>
#include <aws/s3/model/PutObjectRequest.h>
#include <aws/sts/model/AssumeRoleRequest.h>
#include <aws/sts/model/GetCallerIdentityRequest.h>
#include "S3Uploader.h"

#include <iostream>
#include <fstream>
#include <filesystem>

void S3Uploader::init()
{
}

int S3Uploader::upload()
{
    std::cout << "Begin" << std::endl;
    Aws::SDKOptions options;
    Aws::InitAPI(options);
    Aws::Client::ClientConfiguration clientConfig;
    clientConfig.region = "eu-west-2";

    Aws::Auth::DefaultAWSCredentialsProviderChain provider;
    auto credentials = provider.GetAWSCredentials();

    auto myClient = new Aws::STS::STSClient(credentials);
    Aws::STS::Model::GetCallerIdentityRequest myClientCallId;
    auto myClientResult = myClient->GetCallerIdentity(myClientCallId);
    std::cout << "Arn is " << myClientResult.GetResult().GetArn() << std::endl;

    auto assumeRoleRequest = Aws::STS::Model::AssumeRoleRequest();
    assumeRoleRequest.SetDurationSeconds(1600);
    assumeRoleRequest.SetRoleSessionName("Session1");
    assumeRoleRequest.SetRoleArn("arn:aws:iam::529447745127:role/stirlingx_flight_log_role");
    auto assumeRoleOutcome = myClient->AssumeRole(assumeRoleRequest);

    if (assumeRoleOutcome.IsSuccess())
    {
        Aws::STS::Model::Credentials sessionCredentials = assumeRoleOutcome.GetResult().GetCredentials();
        Aws::Auth::AWSCredentials awsSessionCredentials(sessionCredentials.GetAccessKeyId(), sessionCredentials.GetSecretAccessKey(), sessionCredentials.GetSessionToken());

        auto assumedClient = new Aws::STS::STSClient(awsSessionCredentials);

        Aws::STS::Model::GetCallerIdentityRequest callId;

        auto result = assumedClient->GetCallerIdentity(callId);

        std::cout << "Assumed Arn is " << result.GetResult().GetArn() << std::endl;

        const Aws::String bucketName = "stirlingxflightlogs";

        Aws::S3::S3Client s3Client(awsSessionCredentials);

        Aws::S3::Model::ListObjectsV2Request listObjectRequest;
        listObjectRequest.SetBucket(bucketName);

        auto outcome = s3Client.ListObjectsV2(listObjectRequest);

        if (outcome.IsSuccess())
        {
            auto objects = outcome.GetResult().GetContents();
            for (const auto &obj : objects)
            {
                std::cout << "Object Key: " << obj.GetKey() << " Size: " << obj.GetSize() << std::endl;
            }
        }
        else
        {
            std::cerr << "Failed to list object " << outcome.GetError() << std::endl;
        }

        std::filesystem::path fullPath = "C:/Ports.txt";

        Aws::S3::Model::PutObjectRequest putObjectRequest;

        std::shared_ptr<Aws::IOStream> inputData = Aws::MakeShared<Aws::FStream>("tag", fullPath, std::ios_base::in | std::ios_base::binary);

        if (!*inputData)
        {
            std::cerr << " Error unable to read File " << fullPath.filename().string() << std::endl;
            return 1;
        }

        putObjectRequest.SetBucket(bucketName);
        putObjectRequest.SetKey(fullPath.filename().string());
        putObjectRequest.SetBody(inputData);

        Aws::S3::Model::PutObjectOutcome putOutcome = s3Client.PutObject(putObjectRequest);

        if (putOutcome.IsSuccess())
        {
            std::cout << "Added Object " << fullPath.filename().string() << " to bucket " << bucketName << std::endl;
        }
        else
        {
            std::cerr << "Error: Put Object: " << putOutcome.GetError().GetMessage() << std::endl;
        }
    }
    else
    {
        std::cerr << "Failed to assume role: " << assumeRoleOutcome.GetError().GetMessage() << std::endl;
    }
    std::cout << "Finished with S3 bucket and user" << std::endl;

    Aws::ShutdownAPI(options);

    return 0;
}
