package no.pgr301.exam.service;

import io.micrometer.core.instrument.DistributionSummary;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import java.util.UUID;

@Service
public class S3Service {

    private final S3Client s3;
    private final String bucket;
    private final Timer uploadTimer;
    private final DistributionSummary imageSize;

    public S3Service(S3Client s3, @Value("${app.s3.bucket}") String bucket, MeterRegistry registry) {
        this.s3 = s3;
        this.bucket = bucket;
        this.uploadTimer = Timer.builder("wishifai.s3.upload.latency")
                .description("Latency for S3-bildeopplastning")
                .publishPercentiles(0.5, 0.9)
                .register(registry);
        this.imageSize = DistributionSummary.builder("wishifai.image.size")
                .description("Bildestørrelse i bytes")
                .baseUnit("bytes")
                .register(registry);
    }

    public String upload(byte[] bytes, String originalName, String contentType) {
        imageSize.record(bytes.length);
        String key = "uploads/" + UUID.randomUUID() + "-" + (originalName == null ? "image" : originalName);
        uploadTimer.record(() -> s3.putObject(
                PutObjectRequest.builder()
                        .bucket(bucket)
                        .key(key)
                        .contentType(contentType == null ? "application/octet-stream" : contentType)
                        .build(),
                RequestBody.fromBytes(bytes)
        ));
        return key;
    }
}