package io.github.iweidujiang.scaorder.feign;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

import java.math.BigDecimal;

/**
 * ┌───────────────────────────────────────────────
 * │ 📦 商品服务RPC
 * │
 * │ 👤 作者：苏渡苇
 * │ 🔗 微信公众号：苏渡苇
 * │ 💻 GitHub：https://github.com/iweidujiang
 * │ 📅 @since：2026/1/18
 * └───────────────────────────────────────────────
 */
@FeignClient("sca-product")
public interface ProductFeignClient {

    @GetMapping("/product/price/{id}")
    BigDecimal getPrice(@PathVariable("id") Long id);
}
