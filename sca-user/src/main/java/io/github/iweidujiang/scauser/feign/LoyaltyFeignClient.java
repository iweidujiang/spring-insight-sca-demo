package io.github.iweidujiang.scauser.feign;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;

/**
 * 调用积分服务（sca-loyalty），路径与 {@code LoyaltyController} 一致。
 */
@FeignClient(name = "sca-loyalty", contextId = "loyaltyClient")
public interface LoyaltyFeignClient {

    @GetMapping("/loyalty/score/{id}")
    Integer getScore(@PathVariable("id") Long id);

    @GetMapping("/loyalty/addScore")
    Integer addScore(@RequestParam(value = "id") Long id,
                     @RequestParam(value = "lastScore") Integer lastScore,
                     @RequestParam(value = "addScore") Integer addScore);

}
