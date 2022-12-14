<template>
  <div>
    <Table
      title="Transactions"
      :isLoading="$apollo.queries.paginatedTransactions.loading"
      description="List of transactions including their reference, category, date and amount"
      :hasData="paginatedTransactions?.edges.length > 0"
    >
      <template slot="filters">
        <div class="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
          <Input
            leadingIcon
            label="Search"
            placeholder="Search"
            name="search"
            @change="search = $event"
            :disabled="$apollo.queries.paginatedTransactions.loading"
          >
            <svg viewBox="0 0 24 24" class="h-4 w-4 fill-current text-gray-500">
              <path
                d="M10 4a6 6 0 100 12 6 6 0 000-12zm-8 6a8 8 0 1114.32 4.906l5.387 5.387a1 1 0 01-1.414 1.414l-5.387-5.387A8 8 0 012 10z"
              ></path>
            </svg>
          </Input>
          <AutoComplete
            :disabled="$apollo.queries.paginatedTransactions.loading"
            name="Banks"
            :options="autocompleteAccountBanks"
            optionValueKey="bank"
            optionIdentifierKey="bank"
            @change="bankSearch = $event"
            @selected="bank = $event"
          />
          <AutoComplete
            :disabled="$apollo.queries.paginatedTransactions.loading"
            name="Category"
            :options="autocompleteCategory"
            optionValueKey="name"
            optionIdentifierKey="id"
            @change="categorySearch = $event"
            @selected="selectedCategoryId = $event"
          />
          <Input
            trailingIcon
            label="Starting month"
            placeholder="yyyy-mm"
            name="starting_month"
            @change="startingMonth = $event"
            :disabled="$apollo.queries.paginatedTransactions.loading"
            :isInvalid="this.invalidStartingMonth"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-6 w-6 text-gray-500"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              stroke-width="2"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
              />
            </svg>
          </Input>
          <Input
            trailingIcon
            label="Ending month"
            placeholder="yyyy-mm"
            name="ending_month"
            @change="endingMonth = $event"
            :disabled="$apollo.queries.paginatedTransactions.loading"
            :isInvalid="this.invalidEndingMonth"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-6 w-6 text-gray-500"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              stroke-width="2"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
              />
            </svg>
          </Input>
        </div>
      </template>
      <template slot="header">
        <TableHead title="Reference" :isFirst="true" />
        <TableHead title="Category" />
        <TableHead
          hasSort
          :sortField="sortField"
          :sortDirection="sortDirection"
          field="date"
          title="Date"
          @click="updateSortFieldAndDirection"
          :loading="$apollo.queries.paginatedTransactions.loading"
        />
        <TableHead
          hasSort
          :sortField="sortField"
          :sortDirection="sortDirection"
          field="amount"
          title="Amount"
          @click="updateSortFieldAndDirection"
          :loading="$apollo.queries.paginatedTransactions.loading"
        />
      </template>
      <template slot="body">
        <tr
          v-for="transaction in paginatedTransactions?.edges"
          :key="transaction.node.id"
          class="cursor-pointer hover:bg-gray-50"
          @click="view(transaction.node.id)"
        >
          <TableColumn :isFirst="true">
            <span v-if="transaction.node.reference">
              {{ transaction.node.reference }}
            </span>

            <span v-else class="text-sm text-gray-500">
              No reference provided
            </span>
          </TableColumn>
          <TableColumn>
            <Badge :color="transaction.node.Category?.color">
              {{
                transaction.node.Category?.name
                  ? transaction.node.Category?.name
                  : transaction.node.Category?.color
              }}
            </Badge>
          </TableColumn>
          <TableColumn>
            <Date :date="transaction.node.date" />
          </TableColumn>
          <TableColumn>
            <Amount
              containerClass="flex justify-between items-center"
              :amount="transaction.node.amount"
              :currency="transaction.node.currency"
            />
          </TableColumn>
        </tr>
      </template>
    </Table>
    <Pagination
      v-if="paginatedTransactions?.edges.length > 0"
      :disabled="$apollo.queries.paginatedTransactions.loading"
      :resource="paginatedTransactions"
      @showMore="showMore"
    />
  </div>
</template>

<script lang="ts">
import Vue from 'vue'

import { autocompleteAccountBanks } from '~/graphql/accounts/queries/autocompleteAccountBanks'
import { paginatedTransactions } from '~/graphql/transactions/queries/paginatedTransactions'
import { autocompleteCategory } from '~/graphql/categories/queries/autocompleteCategory'

import {
  Account,
  Category,
  TransactionResponse,
  TransactionEdge,
  QueryPaginatedTransactionsArgs,
} from '~/static/types/generated'

const dateRegex = /^\d{4}-\d{2}-\d{2}$/

export default Vue.extend({
  data() {
    return {
      search: '',
      bankSearch: '',
      bank: '',
      categorySearch: '',
      selectedCategoryId: '',
      startingMonth: '',
      endingMonth: '',
      invalidStartingMonth: false,
      invalidEndingMonth: false,
      page: 1,
      sortField: '',
      sortDirection: '',
    }
  },
  head() {
    return {
      title: 'Transactions',
      meta: [
        {
          hid: 'description',
          name: 'description',
          content: 'List of transactions',
        },
      ],
    }
  },
  methods: {
    view(id: string) {
      this.$router.push(`/transactions/${id}`)
    },
    updateSortFieldAndDirection(direction: 'asc' | 'desc', field: 'date') {
      this.sortDirection = direction
      this.sortField = field

      this.applyFilters()
    },
    showMore(endCursor: string) {
      this.page += 1

      this.$apollo.queries.paginatedTransactions.fetchMore({
        variables: this.getPaginatedTransactionVariables(endCursor),

        updateQuery: (
          previousResult: {
            paginatedTransactions: {
              edges: Array<TransactionEdge>
            }
          },
          {
            fetchMoreResult,
          }: {
            fetchMoreResult: {
              paginatedTransactions: {
                edges: Array<TransactionEdge>
              }
            }
          }
        ) => {
          fetchMoreResult.paginatedTransactions.edges = [
            ...previousResult.paginatedTransactions.edges,
            ...fetchMoreResult.paginatedTransactions.edges,
          ]
          return fetchMoreResult
        },
      })
    },
    applyFilters() {
      this.page = 1

      this.$apollo.queries.paginatedTransactions.fetchMore({
        variables: this.getPaginatedTransactionVariables(),
        updateQuery: (
          _previousResult: TransactionResponse,
          { fetchMoreResult }: { fetchMoreResult: TransactionResponse }
        ) => {
          return fetchMoreResult
        },
      })
    },
    reloadBanks() {
      this.$apollo.queries.autocompleteAccountBanks.fetchMore({
        variables: {
          search: this.bankSearch,
        },

        updateQuery: (
          _previousResult: Array<Account>,
          { fetchMoreResult }: { fetchMoreResult: Array<Account> }
        ) => {
          return fetchMoreResult
        },
      })
    },
    reloadCategory() {
      this.$apollo.queries.autocompleteCategory.fetchMore({
        variables: {
          search: this.categorySearch,
        },

        updateQuery: (
          _previousResult: Array<Category>,
          { fetchMoreResult }: { fetchMoreResult: Array<Category> }
        ) => {
          return fetchMoreResult
        },
      })
    },
    dateIsValid(dateStr: string) {
      const regex = /^\d{4}-\d{2}$/

      if (dateStr.match(regex) === null) {
        return false
      }

      const date = new Date(dateStr)

      const timestamp = date.getTime()

      if (typeof timestamp !== 'number' || Number.isNaN(timestamp)) {
        return false
      }

      return date.toISOString().startsWith(dateStr)
    },
    getPaginatedTransactionVariables(endCursor = false as false | string) {
      let variables = {
        search: this.search,
        bank: this.bank,
        categoryId: this.selectedCategoryId,
        startingMonth: this.startingMonth,
        endingMonth: this.endingMonth,
        sortField: this.sortField,
        sortDirection: this.sortDirection,
      } as QueryPaginatedTransactionsArgs

      if (endCursor) {
        variables.skip = endCursor
      }

      if (this.sortField) {
        variables.page = this.page
      }

      return variables
    },
  },
  watch: {
    search() {
      this.applyFilters()
    },
    bankSearch() {
      this.reloadBanks()
    },
    categorySearch() {
      this.reloadCategory()
    },
    bank() {
      this.applyFilters()
    },
    selectedCategoryId() {
      this.applyFilters()
    },
    startingMonth() {
      if (this.dateIsValid(this.startingMonth)) {
        this.invalidStartingMonth = false
        this.applyFilters()
      } else {
        if (this.startingMonth) {
          this.invalidStartingMonth = true
        } else {
          this.invalidStartingMonth = false
        }
      }
    },
    endingMonth() {
      if (this.dateIsValid(this.endingMonth)) {
        this.invalidEndingMonth = false

        this.applyFilters()
      } else {
        if (this.endingMonth) {
          this.invalidEndingMonth = true
        } else {
          this.invalidEndingMonth = false
        }
      }
    },
  },
  apollo: {
    paginatedTransactions: {
      query: paginatedTransactions,
      variables: {
        take: 10,
        search: '',
      },
    },
    autocompleteAccountBanks: {
      query: autocompleteAccountBanks,
      variables: {
        search: '',
      },
    },
    autocompleteCategory: {
      query: autocompleteCategory,
      variables: {
        search: '',
      },
    },
  },
})
</script>
