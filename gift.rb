require 'colorize'

#----------------------------------------------------------------------------------------------------
#- Проверяет исполнение правила. Правило описано в 2-х мерном массиве. 1-й уровень: OR, 2-й - AND ---
def check_rule order, goods_arr_rules
  rule_result = 0
  goods_arr_rules.each do |rule|
    rule_result = 1
    rule.each do |good_name|
      rule_result *= order[good_name].exists? ? 1 : 0
    end
    break if rule_result == 1
  end
  rule_result == 1
end

#----------------------------------------------------------------------------------------------------
#- Итерирует по правилам, последовательно применяя их к ордеру. Товары, участвовавшие в скидке -
#  отбрасываются и не участвуют следующей итерации
def pop_good_groups_by_rules order, gift_groups

  gift_maked = false #10. Каждый товар может участвовать только в одной скидке. Скидки применяются последовательно в порядке описанном выше.

  $rules.each do |rule|
    if rule[:goods]
      rule[:goods].each do |goods_set|
        if check_rule order, [goods_set]
          make_rule_gift order, gift_groups, goods_set, rule[:percentage]
#          puts rule.inspect.magenta
          gift_maked = true
          break
        end
      end
    elsif rule[:quantity]
      total_cost = 0
      total_quantity = 0
      total_gift = {}
      order.each do |good_name, quantity|
        if quantity > 0 && (!rule[:exclude] || (rule[:exclude] && !rule[:exclude].include?(good_name)))
          # 9. Продукты A и C не участвуют в скидках 5,6,7
          total_quantity += quantity
          total_cost += quantity * $goods[good_name][:price]
          total_gift[good_name] = quantity
        end
      end
      if total_quantity >= 0 && rule[:quantity] === total_quantity
        make_quantity_gift order, gift_groups, total_gift, total_cost, rule[:percentage]
        gift_maked = true
        break
      end
    end
    #### 8. Описанные скидки 5,6,7 не суммируются, применяется только одна из них
    break if gift_maked #10. Каждый товар может участвовать только в одной скидке. Скидки применяются последовательно в порядке описанном выше.
  end

end

#---------------------------------------------------------------------------------------------
def make_quantity_gift(order, gift_groups, total_gift, total_cost, percentage)
  total_gift.each do |good_name, quantity|
    order[good_name] -= quantity
  end
  total_gift[:gift] = {total: (total_cost * percentage).round(2), percentage: percentage}
  gift_groups << total_gift
end

#---------------------------------------------------------------------------------------------
def make_rule_gift order, gift_groups, goods_by_rule, percentage
  gift_hash = goods_by_rule.each_with_object({}){|r, h|h[r] = 1}
  good_prices = 0
  goods_by_rule.each do |good_name|
    good_prices += $goods[good_name][:price]
  end
  gift_hash[:gift] = {total: (good_prices * percentage).round(2), percentage: percentage}
  gift_groups << gift_hash
  goods_by_rule.each do |good_name|
    order[good_name] -= 1
  end
end

#---------------------------------------------------------------------------------------------------------------------------------------
def order_string good_name, quantity, unit_price
  "#{good_name.to_s.rjust(16)} | #{quantity.to_s.rjust(8)} | #{unit_price.to_s.rjust(10)} | #{(quantity * unit_price).round(2).to_s.rjust(10)}"
end

#-------------------------------
class Float
  def exists?
    self > 0
  end
end

#-------------------------------
class Fixnum
  def exists?
    self > 0
  end
end

#-------------------------------
class NilClass
  def exists?
    false
  end
end


#---------------------------------------------------------------------------------------------------------------------------------------
$rules = [
  # 1. Если одновременно выбраны А и B, то их суммарная стоимость уменьшается на 10% (для каждой пары А и B)
  {goods: [["A", "B"]], percentage: 0.1},
  # 2. Если одновременно выбраны D и E, то их суммарная стоимость уменьшается на 5% (для каждой пары D и E)
  {goods: [["D", "E"]], percentage: 0.05},
  # 3. Если одновременно выбраны E,F,G, то их суммарная стоимость уменьшается на 5% (для каждой тройки E,F,G)
  {goods: [["E", "F", "G"]], percentage: 0.05},
  # 4. Если одновременно выбраны А и один из [K,L,M], то стоимость выбранного продукта уменьшается на 5%
  {goods: [["A", "K"], ["A", "L"], ["A", "M"]], percentage: 0.05},
  # 5. Если пользователь выбрал одновременно 3 продукта, он получает скидку 5% от суммы заказа
  {quantity: (3..3), exclude: ["A", "C"], percentage: 0.05},
  # 6. Если пользователь выбрал одновременно 4 продукта, он получает скидку 10% от суммы заказа
  {quantity: (4..4), exclude: ["A", "C"], percentage: 0.1},
  # 7. Если пользователь выбрал одновременно 5 продуктов, он получает скидку 20% от суммы заказа
  {quantity: (5..Float::INFINITY), exclude: ["A", "C"], percentage: 0.2}
  #### 9. Продукты A и C не участвуют в скидках 5,6,7
]

$goods = {
 "A" => {price: 10.11},
 "B" => {price: 11.12},
 "C" => {price: 13.14},
 "D" => {price: 15.16},
 "E" => {price: 17.18},
 "F" => {price: 19.20},
 "G" => {price: 21.22},
 "H" => {price: 23.24},
 "I" => {price: 25.26},
 "J" => {price: 27.28},
 "K" => {price: 29.30},
 "L" => {price: 31.32},
 "M" => {price: 33.34}
}

orders = {
 "Order # 1" => {"A" => 2, "B" => 1, "K" => 2, "M" => 3},
 "Order # 2" => {"B" => 2, "C" => 1, "D" => 1, "E" => 3, "F" => 5, "G" =>2},
 "Order # 3" => {"A" => 2, "C" => 1, "D" => 1, "E" => 3, "F" => 5, "G" =>3},
 "Order # 4" => {"A" => 4, "K" => 1, "L" => 2, "B" => 1, "C" => 5, "F" =>3, "M" => 3, "D" => 7, "E" => 5, "F" => 3, "G" => 3}
}

orders.each do |order_name, order|
  order_stub = order.clone
  gift_groups = []

  while true do
    order_backup = order_stub.clone
    pop_good_groups_by_rules order_stub, gift_groups
    break if order_backup == order_stub
  end

#  puts order.inspect.magenta

  puts "================= #{order_name.center(17)} =================".yellow
  puts "Good description | Quantity | Unit Price | Line Total"
  order_stub = order.clone
  gift_groups.each do |gift|
    gift.each do |key, value|
      if key == :gift
        puts "Gift (#{value[:percentage]*100}%): #{value[:total]}".rjust(53).green
      else
        order_stub[key] -= value
        puts order_string(key, value, $goods[key][:price])
      end
    end
  end
  order_stub.delete_if{|key, value|value <= 0}
  order_stub.each do |good_name, count|
    puts order_string good_name, count, $goods[good_name][:price]
  end
  puts "================= #{'Total'.center(17)} =================".yellow
  grand_total = order.each_with_object([]){|(key, value), gt| gt << $goods[key][:price] * value}.inject{|sum,x| sum + x }.round(2)
  puts "Total (without gifts): #{sprintf('%.2f', grand_total)}".rjust(53)
  gift_total = gift_groups.map{|x|x[:gift][:total]}.inject{|sum,x| sum + x }.round(2)
  puts "Gift total: #{sprintf('%.2f', gift_total)}".rjust(53).green
  puts "Grand total: #{sprintf('%.2f', grand_total - gift_total)}".rjust(53).yellow

  puts "\n\n"
end

