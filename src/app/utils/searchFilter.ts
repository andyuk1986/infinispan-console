import { RoleFilterOption } from '@services/infinispanRefData';

/**
 * Utility function to help filters the list of items based on the search value
 * @param value - value to search
 * @param listItem - item to search from
 */
export const onSearch = (value: string, listItem: string): boolean => {
  let searchValueInput: RegExp;
  try {
    searchValueInput = new RegExp(value, 'i');
  } catch (err) {
    searchValueInput = new RegExp(value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');
  }
  const matchesSearchValue = listItem.search(searchValueInput) >= 0;

  return value === '' || matchesSearchValue;
};

/**
 * Utility function to help filters the list of items based on the search value
 * @param value - value to search
 * @param listItem - list of items to search
 */
export const onFilter = (value: string, listItem: string) => {
  let searchValueInput: RegExp;
  try {
    searchValueInput = new RegExp(value, 'i');
  } catch (err) {
    searchValueInput = new RegExp(value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');
  }
  const matchesSearchValue = listItem.search(searchValueInput) >= 0;

  return value === '' || matchesSearchValue;
};
