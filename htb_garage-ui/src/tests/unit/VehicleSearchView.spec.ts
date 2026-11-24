import { describe, it, expect } from 'vitest';
import { mount } from '@vue/test-utils';
import VehicleSearchView from '@/views/VehicleSearchView.vue';

describe('VehicleSearchView', () => {
  it('renders search input with placeholder', () => {
    const wrapper = mount(VehicleSearchView);
    const input = wrapper.find('input[type="text"]');
    expect(input.exists()).toBe(true);
    expect(input.attributes('placeholder')).toBe('Search by plate or name');
  });

  it('updates search input binding', async () => {
    const wrapper = mount(VehicleSearchView);
    const input = wrapper.find('input');
    await input.setValue('ABC123');
    expect((input.element as HTMLInputElement).value).toBe('ABC123');
  });

  it('renders McLaren and Zentorno items', () => {
    const wrapper = mount(VehicleSearchView);
    expect(wrapper.text()).toContain('McLaren ABC123');
    expect(wrapper.text()).toContain('Zentorno DEF456');
  });
});
