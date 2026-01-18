package io.github.iweidujiang.scaorder.controller;

import io.github.iweidujiang.scaorder.feign.ProductFeignClient;
import io.github.iweidujiang.scaorder.feign.UserFeignClient;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

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

    @GetMapping("/create")
    public String createOrder(@RequestParam("userId") Long userId, @RequestParam("productId") Long productId) {
        log.info("创建订单参数，userId={}, productId={}", userId, productId);
        // 商品服务-获取价格
        BigDecimal price = productFeignClient.getPrice(productId);
        log.info("获得 price={}", price);
        // 用户服务-查询当前积分，增加积分
        Integer currentScore = userFeignClient.getScore(userId);
        log.info("获得 currentScore={}", price);
        // 增加积分
        Integer addScore = price.intValue();
        Integer finalScore = userFeignClient.addScore(userId, currentScore, addScore);
        log.info("下单成功，用户 id={} 最终积分：{}", userId, finalScore);
        return "下单成功，用户 id=" + userId + " 最终积分：" + finalScore;
    }

}
