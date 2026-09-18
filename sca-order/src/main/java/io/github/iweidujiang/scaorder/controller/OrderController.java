package io.github.iweidujiang.scaorder.controller;

import io.github.iweidujiang.scaorder.feign.ProductFeignClient;
import io.github.iweidujiang.scaorder.feign.UserFeignClient;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestTemplate;

import java.math.BigDecimal;

/**
 * ┌───────────────────────────────────────────────
 * │ 📦 订单管理
 * │
 * │ 👤 作者：苏渡苇
 * │ 🔗 微信公众号：苏渡苇
 * │ 💻 GitHub：https://github.com/iweidujiang
 * │ 📅 @since：2026/1/18
 * └───────────────────────────────────────────────
 */
@Slf4j
@RestController
@RequestMapping("/order")
public class OrderController {

    @Autowired
    private UserFeignClient userFeignClient;

    @Autowired
    private ProductFeignClient productFeignClient;

    @Autowired
    private RestTemplate loadBalancedRestTemplate;

    @Autowired
    private RestClient restClient;

    /** RestClient 造数直连基址（默认本机 product 端口） */
    @Value("${demo.product-base-url:http://127.0.0.1:18082}")
    private String productBaseUrl;

    @GetMapping("/create")
    public String createOrder(@RequestParam("userId") Long userId, @RequestParam("productId") Long productId) {
        log.info("创建订单参数，userId={}, productId={}", userId, productId);
        // 商品服务-获取价格
        BigDecimal price = productFeignClient.getPrice(productId);
        log.info("获得 price={}", price);
        // 用户服务-查询当前积分，增加积分
        Integer currentScore = userFeignClient.getScore(userId);
        log.info("获得 currentScore={}", currentScore);
        // 增加积分
        Integer addScore = price.intValue();
        Integer finalScore = userFeignClient.addScore(userId, currentScore, addScore);
        log.info("下单成功，用户 id={} 最终积分：{}", userId, finalScore);
        return "下单成功，用户 id=" + userId + " 最终积分：" + finalScore;
    }

    /**
     * RestTemplate CLIENT 造数：{@code remoteService=sca-product}（LoadBalancer host）。
     *
     * @param productId 商品 ID
     * @return 价格
     */
    @GetMapping("/ping-rt")
    public String pingRestTemplate(@RequestParam(value = "productId", defaultValue = "1") Long productId) {
        BigDecimal price = loadBalancedRestTemplate.getForObject(
                "http://sca-product/product/price/{id}", BigDecimal.class, productId);
        return "rt-price=" + price;
    }

    /**
     * RestClient CLIENT 造数：直连 URL，{@code remoteService} 为 host（如 127.0.0.1）。
     *
     * @param productId 商品 ID
     * @return 价格
     */
    @GetMapping("/ping-rc")
    public String pingRestClient(@RequestParam(value = "productId", defaultValue = "1") Long productId) {
        BigDecimal price = restClient.get()
                .uri(productBaseUrl + "/product/price/{id}", productId)
                .retrieve()
                .body(BigDecimal.class);
        return "rc-price=" + price;
    }

}
