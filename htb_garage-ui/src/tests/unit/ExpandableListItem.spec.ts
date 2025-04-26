import { describe, it, expect } from 'vitest';
import { mount } from '@vue/test-utils';
import ExpandableListItem from '@/components/ui/ExpandableListItem.vue';

describe('ExpandableListItem', () => {
  it('starts collapsed by default', () => {
    const wrapper = mount(ExpandableListItem, {
      slots: {
        header: '<div>Header</div>',
        detail: '<div class="details">Details content</div>',
      },
    });
    expect(wrapper.find('.details').exists()).toBe(false);
  });

  it('starts expanded if `open` prop is true', async () => {
    const wrapper = mount(ExpandableListItem, {
      props: { open: true },
      slots: {
        header: '<div>Header</div>',
        detail: '<div class="details">Details content</div>',
      },
    });
    expect(wrapper.find('.details').isVisible()).toBe(true);
  });

  it('toggles details on header click', async () => {
    const wrapper = mount(ExpandableListItem, {
      slots: {
        header: '<div class="header">Click me</div>',
        detail: '<div class="details">Details content</div>',
      },
    });

    expect(wrapper.find('.details').exists()).toBe(false);
    await wrapper.find('.header').trigger('click');
    expect(wrapper.find('.details').isVisible()).toBe(true);
  });
});
