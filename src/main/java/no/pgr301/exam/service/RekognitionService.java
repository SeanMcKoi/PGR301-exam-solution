package no.pgr301.exam.service;

import io.micrometer.core.instrument.DistributionSummary;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.core.SdkBytes;
import software.amazon.awssdk.services.rekognition.RekognitionClient;
import software.amazon.awssdk.services.rekognition.model.DetectLabelsRequest;
import software.amazon.awssdk.services.rekognition.model.DetectLabelsResponse;
import software.amazon.awssdk.services.rekognition.model.Image;
import software.amazon.awssdk.services.rekognition.model.Label;

import java.util.List;

@Service
public class RekognitionService {

    private final RekognitionClient client;
    private final Timer detectTimer;
    private final DistributionSummary labelsPerImage;

    public RekognitionService(RekognitionClient client, MeterRegistry registry) {
        this.client = client;
        this.detectTimer = Timer.builder("wishifai.rekognition.latency")
                .description("Latency for rekognition DetectLabels")
                .register(registry);
        this.labelsPerImage = DistributionSummary.builder("wishifai.rekognition.labels")
                .description("Antall labels per bilde")
                .register(registry);
    }

    public List<String> detectLabels(byte[] bytes) {
        DetectLabelsResponse resp = detectTimer.record(() -> client.detectLabels(DetectLabelsRequest.builder()
                .image(Image.builder().bytes(SdkBytes.fromByteArray(bytes)).build())
                .maxLabels(20)
                .minConfidence(70f)
                .build()));

        List<String> labels = resp.labels().stream().map(Label::name).toList();
        labelsPerImage.record(labels.size());
        return labels;
    }
}