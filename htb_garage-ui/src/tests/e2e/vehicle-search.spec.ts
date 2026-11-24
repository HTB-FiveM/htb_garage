import { test, expect } from '@playwright/test';

test('Vehicle search view loads and allows expansion', async ({ page }) => {
  await page.goto('http://localhost:5173');

  await expect(page.getByPlaceholder('Search by plate or name')).toBeVisible();
  await page.getByPlaceholder('Search by plate or name').fill('DEF456');

  const mcLaren = await page.locator('text=McLaren ABC123');
  const zentorno = await page.locator('text=Zentorno DEF456');

  await expect(mcLaren).toBeVisible();
  await expect(zentorno).toBeVisible();

  const statBlock = await page.locator('text=Acceleration');
  await expect(statBlock).toBeVisible();

  // Simulate clicking Zentorno to collapse it
  await zentorno.click();
  await expect(statBlock).toBeHidden();
});
